classdef TrialStackController < handle
    properties
        model
        view
    end
    
    methods
        function self = TrialStackController(mymodel)
            self.model = mymodel;
            self.view = trialStack.TrialStackView(self.model,self);
            MaxTrialnumber = self.model.getMaxTrialnumber;
            self.view.setTrialNumberandSliderLim(1,[1,MaxTrialnumber]);
            self.view.displayCurrentMap();
            self.view.redrawAllRoiAsOnePatch();
            if ~isempty(mymodel.transformationParameter)
                self.view.displayTransformationData(mymodel.transformationParameter);
                if ~isempty(mymodel.transformationName)
                    self.view.displayTransformationName(mymodel.transformationName);
                end
            end
        end
        
        
        function ScrollWheelFcnCallback(self, src, evnt)
        %JE-Mouswheelscroll functionality for scrolling trough the trials
        %TO DO: zoom function can casues problems and should be deactivated first
            tempTrial =self.model.currentTrialIdx-round(evnt.VerticalScrollCount); % - to get the direction as i prefer it, JE
            self.model.currentTrialIdx = tempTrial;
            self.view.setTrialNumberSlider(self.model.currentTrialIdx);
        end

        function keyPressCallback(self, src, evnt)
            if isempty(evnt.Modifier)
                switch evnt.Key
                  case {'j','k'}
                    self.slideTrialCallback(evnt)
                  case 'q'
                    self.model.selectMapType(1)
                  case 'w'
                    self.model.selectMapType(2)
                  case 'v'
                    self.enterMoveRoiMode();
                  case {'d','delete','backspace'}
                    self.deleteSelectedRoi();
                end
            end
        end

        function SaveRoiNormal_Callback(self,src,evnt)
            self.model.SaveRoiNormal();
        end

        function ExportRois_Callback(self,src,evnt)
            self.model.ExportRois();
        end

        function selectRoi_Callback(self,src,evnt)
            selectedObj = gco;
            if RoiFreehand.isaRoiPatch(selectedObj)
                self.roiClicked_Callback(selectedObj);
            elseif isequal(selectedObj, ...
                           self.view.guiHandles.mapImage)
                if ~isempty(self.model.selectedRoiTagArray)
                    self.model.unselectAllRoi();
                end
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

        function enterMoveRoiMode(self)
        % ENTERMOVEROIMODE callback to enter moving mode of
        % selected ROIs
            self.view.changeRoiPatchColor('y','selected');
            mainFig = self.view.guiHandles.mainFig;
            usrData = get(mainFig,'UserData');
            usrData.oldWindowButtonDownFcn = get(mainFig,'WindowButtonDownFcn');
            usrData.oldWindowKeyPressFcn = get(mainFig, ...
                                               'WindowKeyPressFcn');
            
            % Initialize moveit data
            currentRoiPatch = self.view.selectedRoiPatchArray{1};
            usrData.moveitData.currentRoiPatch = currentRoiPatch;
            usrData.moveitData.originalXYData = {get(currentRoiPatch,'XData') get(currentRoiPatch,'YData')};
            
            set(mainFig,'WindowButtonDownFcn',@ ...
                        self.moveRoi_Callback);
            % press Esc Callback
            set(self.view.guiHandles.mainFig,'WindowKeyPressFcn', ...
                              @(s,e)self.moveRoiKeyPressCallback(s,e));
            set(mainFig,'UserData',usrData);

        end

           function exitMoveRoiMode(self,src,status)
            thisFig = ancestor(src,'figure');
            thisAxes = get(thisFig,'CurrentAxes');
            usrData = get(thisFig,'UserData');
            if strcmp(status,'success') && ...
                    isfield(usrData.moveitData,'startPoint') && ...
                    isfield(usrData.moveitData,'pos')
                % if exit with success, update the roi position in
                % trial model
                startPoint = usrData.moveitData.startPoint;
                relativePos = usrData.moveitData.pos;
                movedPatch = usrData.moveitData.currentHandle;
                pttag = movedPatch.Tag;
                roiTag = helper.convertTagToInd(pttag,'roi');
                axesPos = [movedPatch.XData,movedPatch.YData];
                self.model.updateRoi(roiTag,thisAxes,axesPos);
            else
                movedPatch = usrData.moveitData.currentRoiPatch;
                XYData = usrData.moveitData.originalXYData;
                set(movedPatch,'XData',XYData{1});
                set(movedPatch,'YData',XYData{2});

            end
            self.view.changeRoiPatchColor('default','selected');

            set(thisFig,'WindowButtonDownFcn',...
                        usrData.oldWindowButtonDownFcn);
            set(self.view.guiHandles.mainFig,'WindowKeyPressFcn',...
                              usrData.oldWindowKeyPressFcn);
            rmfield(usrData,'moveitData');
            rmfield(usrData,'oldWindowButtonDownFcn');
            rmfield(usrData,'oldWindowKeyPressFcn');
            set(thisFig,'UserData',usrData);
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
                        self.exitMoveRoiMode(selectedObj,'success');
                    end
                end
            end
        end
        
        function moveRoiKeyPressCallback(self,src,evnt)
            if isempty(evnt.Modifier) && strcmp(evnt.Key,'escape')
                selectedObj = gco;
                self.exitMoveRoiMode(selectedObj,'cancel');
            end
        end
        
        function slideTrialCallback(self,evnt)
            if strcmp(evnt.Key, 'k')
                self.model.currentTrialIdx = self.model.currentTrialIdx+1;
            elseif strcmp(evnt.Key, 'j')
                self.model.currentTrialIdx = self.model.currentTrialIdx-1;
            end
            self.view.setTrialNumberSlider(self.model.currentTrialIdx);
        end

        
        function EditCheckbox_Callback(self,src,evnt)
            self.model.EditCheckbox=src.Value;
            self.view.ChangePatchMode();
        end
        
        function TrialNumberSlider_Callback(self,src,evnt)
        %JE-added scrolling through trials via slider
            NewTrialNumber=round(self.view.getTrialnumberSlider);
            if NewTrialNumber~=self.model.currentTrialIdx %To prevent looping with identical Idx
                self.model.currentTrialIdx=NewTrialNumber;
            end
        end

        function RoiAlphaSlider_Callback(self,src,evnt)
            NewAlpha= self.view.getRoiAlphaSliderValue;
            %self.model.NewAlphaAllRois(NewAlpha); %not needed since we
            %draw them in one patch
            self.view.AlphaForRoiOnePatch=NewAlpha;
            self.view.redrawAllRoiAsOnePatch();
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
            self.model.saveContrastLim(contrastLim);
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
            self.model.saveContrastLim(vcl);
            self.view.setDataLimAndContrastLim(dataLim,vcl);
            self.view.changeMapContrast(vcl);
        end
    end
end