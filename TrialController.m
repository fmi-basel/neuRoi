classdef TrialController < handle
    properties
        model
        view
        nMapMax
    end
    methods
        function self = TrialController(mymodel)
            self.model = mymodel;
            self.nMapMax = 6;
            self.view = TrialView(self.model,self);
            
            % Initialize map display
            self.view.toggleMapButtonValidity(self.model);
            self.view.displayCurrentMap();
        end
        
        function keyPressCallback(self,src,evnt)
            if isempty(evnt.Modifier)
                switch evnt.Key
                  case 'f'
                    self.addRoiByDrawing()
                  case {'d','delete','backspace'}
                    self.deleteSelectedRoi()
                end
            elseif strcmp(evnt.Modifier,'control')
                switch evnt.Key
                % TODO select all ROI
                end
            end
        end
        
        function addMap(self,type,varargin)
            mapArrayLen = self.model.getMapArrayLength();
            if mapArrayLen >= self.nMapMax
                error('Cannot add more than %d maps',nMapButton);
            end
            self.model.calculateAndAddNewMap(type,varargin{:});
            self.model.selectMap(mapArrayLen+1);
        end
        
        function mapButtonSelected_Callback(self,src,evnt)
            tag = evnt.NewValue.Tag;
            ind = helper.convertTagToInd(tag,'mapButton');
            self.model.selectMap(ind);
        end
        
        function contrastSlider_Callback(self,src,evnt)
        % Method to change contrast of map image
            contrastSliderInd = helper.convertTagToInd(src.Tag, ...
                                                       'contrastSlider');
            contrastLim = self.view.getContrastLim();
            dataLim = self.view.getContrastSliderDataLim();
            % Check whether contrastLim is valid (min < max), otherwise set the
            % other slider to a valid value based on the new value of
            % the changed slider;
            if contrastLim(1) >= contrastLim(2)
                contrastLim = ...
                    self.calcMinLessThanMax(contrastSliderInd, ...
                                              contrastLim,dataLim);
                self.view.setContrastLim(contrastLim);
            end
            self.view.changeMapContrast(contrastLim);
            self.model.saveContrastLimToCurrentMap(contrastLim);
        end
        
        function contrastLim = ...
                calcMinLessThanMax(self,contrastSliderInd,contrastLim,dataLim)
            sn = 10000*eps; % a small number
            switch contrastSliderInd
              case 1
                if contrastLim(1) >= dataLim(2)
                    contrastLim(1) = dataLim(2)-sn;
                end
                contrastLim(2) = contrastLim(1)+sn;
              case 2
                if contrastLim(2) <= dataLim(1)
                    contrastLim(2) = dataLim(1)+sn;
                end
                contrastLim(1) = contrastLim(2)-sn;
              otherwise
                error('contrastSliderInd should be 1 or 2 ');
            end
        end
        
        function updateContrastForCurrentMap(self)
        % Set limit and values of the contrast sliders
            map = self.model.getCurrentMap();
            dataLim = helper.minMax(map.data);
            sn = 10000*eps; % a small number
            dataLim(2) = dataLim(2) + sn;

            if isfield(map,'contrastLim')
                contrastLim = map.contrastLim;
                ss = helper.rangeIntersect(dataLim,contrastLim);
                if ~isempty(ss)
                    vcl = ss;
                else
                    vcl = dataLim;
                end
            else
                vcl = dataLim;
            end
            self.model.saveContrastLimToCurrentMap(vcl);
            self.view.setDataLimAndContrastLim(dataLim,vcl);
            self.view.changeMapContrast(vcl);
        end
        
        % Methods for ROI based processing
        function addRoiByDrawing(self)
            rawRoi = imfreehand;
            if ~isempty(rawRoi)
                position = rawRoi.getPosition();
                mapAxes = self.view.guiHandles.mapAxes;
                if ~isempty(position)
                    freshRoi = RoiFreehand(mapAxes,position);
                    self.model.addRoi(freshRoi);
                    self.model.selectSingleRoi('last');
                else
                    disp('Empty ROI. Not added to ROI array.')
                end
                delete(rawRoi)
            end
        end
       
        function selectRoi_Callback(self,src,evnt)
            selectedObj = gco;
            if RoiFreehand.isaRoiPatch(selectedObj)
                self.roiClicked_Callback(selectedObj);
            elseif isequal(selectedObj,self.view.guiHandles.mapImage)
                self.model.unselectAllRoi();
            end
        end
        
        function roiClicked_Callback(self,roiPatch)
            ptTag = roiPatch.Tag;
            roiTag = helper.convertTagToInd(ptTag,'roi');

            selectionType = get(gcf,'SelectionType');
            switch selectionType
              case {'normal','alt'}
                self.model.selectSingleRoi(roiTag);
              case 'extend'
                if strcmp(roiPatch.Selected,'on')
                    self.model.unselectRoi(roiTag);
                else
                    self.model.selectRoi(roiTag);
                end
            end
        end
        
        % Functions for moving selected ROIs
        function enterMoveRoiMode(self)
        % ENTERMOVEROIMODE callback to enter moving mode of
        % selected ROIs
            self.view.changeRoiPatchColor('y','selected');
            mainFig = self.view.guiHandles.mainFig;
            set(mainFig,'WindowButtonDownFcn',@ ...
                        self.moveRoi_Callback);
            % TODO press Esc Callback
        end

        function exitMoveRoiMode(self,src)
        % if exit with success
            thisFig = ancestor(src,'figure');
            thisAxes = get(thisFig,'CurrentAxes');
            usrData = get(thisFig,'UserData');
            startPoint = usrData.moveitData.startPoint;
            relativePos = usrData.moveitData.pos;
            movedPatch = usrData.moveitData.currentHandle;
            if ~isempty(startPoint) && ~isempty(relativePos)
                pttag = movedPatch.Tag;
                roiTag = helper.convertTagToInd(pttag,'roi');
                axesPos = [movedPatch.XData,movedPatch.YData];
                self.model.updateRoi(roiTag,thisAxes,axesPos);
            end
            self.view.changeRoiPatchColor('default','selected');

            rmfield(usrData,'moveitData');
            set(thisFig,'UserData',usrData);
            %     self.model.updateRoiPosition by position shift
            % else
            %     move back the roiPatch to original position
            % end
            
            % set(mainFig,'WindowButtonDownFcn',@self.selectRoi_Callback)

        end
        
        function moveRoi_Callback(self,src,evnt)
            selectedObj = gco;
            selectionType = get(gcf,'SelectionType');
            % If the selected object is a roiPatch that has been
            % already selected, then start to move it
            if RoiFreehand.isaRoiPatch(selectedObj)
                if strcmp(selectedObj.Selected,'on')
                    switch selectionType
                      case 'normal'
                        disp('start moving ROIs')
                        moveit.startmovit(selectedObj);
                        % start point and relative position to
                        % start point are saved in
                        % UserData of parent figure
                      case 'open'
                        self.exitMoveRoiMode(selectedObj);
                    end
                end
            end
        end
        
        function deleteSelectedRoi(self)
            self.model.deleteSelectedRoi();
        end

        
        function setFigTagPrefix(self,prefix)
            self.view.setFigTagPrefix(prefix);
        end
        
        function raiseView(self)
            self.view.raiseFigures();
        end
        
        function mainFigClosed_Callback(self,src,evnt)
            self.view.deleteFigures();
            delete(self.view);
            delete(self.model);
            delete(self);
        end
        
        function delete(self)
            if ishandle(self.view)
                if isvalid(self.view)
                    self.view.deleteFigures();
                    delete(self.view)
                end
            end
        end
    end
end
