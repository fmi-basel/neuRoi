classdef BaseTrialController < handle
    properties
        model
        view
        enableFreehandShortcut
    end
    
    methods
        function keyPressCallback(self, src, evnt)
            if isempty(evnt.Modifier)
                switch evnt.Key
                  case 'f'
                    if self.enableFreehandShortcut
                        self.addRoiByDrawing();
                    end
                  case 'q'
                    self.model.selectMapType(1)
                  case 'w'
                    self.model.selectMapType(2)
                  case 'e'
                    self.model.selectMapType(3)
                  case 't'
                    self.toggleRoiVisibility()
                  case 'x'
                    self.replaceRoiByDrawing();
                  case 'v'
                    self.enterMoveRoiMode();
                  case 'r'
                    self.toggleRoiVisibility();
                  case {'equal','2'}
                    self.view.zoomFcn(-1);
                  case {'hyphen','1'}
                    self.view.zoomFcn(1);
                end
            elseif strcmp(evnt.Modifier,'control')
                switch evnt.Key
                  case 'r'
                    self.selectRoisByOverlay();
                end
            end
            end
        end
        
        function addRoiByDrawing(self, varargin)
            self.view.setRoiVisibility(true);
            self.enableFreehandShortcut = false;
            if length(varargin) == 1
                rawRoi = images.roi.Freehand(self.view.guiHandles.roiAxes,...
                                             'Position', varargin{1});
            else
                rawRoi = drawfreehand(self.view.guiHandles.roiAxes);
            end
            self.addRawRoi(rawRoi);
            self.enableFreehandShortcut = true;
        end
        
        function addRawRoi(self, rawRoi)
            if ~isempty(rawRoi.Position)
                freshRoi = roiFunc.RoiM('freeHand', rawRoi);
                self.model.addRoi(freshRoi);
                self.model.selectLastRoi();
            else
                disp('Empty ROI. Not added to ROI array.')
            end
            delete(rawRoi)
        end

        function replaceRoiByDrawing(self, varargin)
            if self.model.singleRoiSelected()
                roi = self.model.roiArr.getSelectedRois();
                % Remove ROI in view
                self.view.deleteRoiPatch(roi);

                % Draw ROI
                figure(self.view.guiHandles.mainFig);
                self.enableFreehandShortcut = false;
                if length(varargin) == 1
                    rawRoi = images.roi.Freehand(self.view.guiHandles.roiAxes,...
                                                 'Position', varargin{1});
                else
                    rawRoi = drawfreehand(self.view.guiHandles.roiAxes);
                end
                
                % Update ROI
                if ~isempty(rawRoi)
                    position = rawRoi.Position;
                    if ~isempty(position)
                        freshRoi = roiFunc.RoiM('freeHand', rawRoi);
                        self.model.updateRoi(roi.tag, freshRoi);
                        self.model.selectSingleRoi(roi.tag);
                    else
                        disp('Empty ROI. No replacement.')
                    end
                    delete(rawRoi)
                end
                self.enableFreehandShortcut = true;
            else
                error(['Exactly one ROI should be selected for ' ...
                       'replacing!']);
            end
        end
        
        function deleteSelectedRois(self,src,evnt)
            self.model.deleteSelectedRois();
        end

        function roiClicked_Callback(self, src, evnt)
            currPt = get(self.view.guiHandles.roiAxes, 'CurrentPoint');
            if self.checkWithinRoiAxes(currPt)
                % get Tag value under currPt
                roiMask = self.view.getRoiMask();
                tag = roiMask(round(currPt(1,2)), round(currPt(1,1)));
                % select Roi accordingly
                if tag > 0
                    self.selectRoi_Callback(tag);
                else
                    if ~isempty(self.model.roiArr.getSelectedIdxs())
                        self.model.unselectAllRois();
                    end
                end
            end
        end
        
        function result = checkWithinRoiAxes(self, currPt)
            ax = self.view.guiHandles.roiAxes;
            xlim = get(ax,'xlim');
            ylim = get(ax,'ylim');
            outX = any(diff([xlim(1), currPt(1,1), xlim(2)])<0);
            outY = any(diff([ylim(1), currPt(1,2), ylim(2)])<0);
            result = ~(max(outX, outY));
        end

        function selectRoi_Callback(self, tag)
            selectionType = get(gcf,'SelectionType');
            switch selectionType
              case 'normal'
                self.model.selectSingleRoi(tag);
              case 'alt'
                selectedTags = self.model.roiArr.getSelectedTags();
                if ismember(tag, selectedTags)
                    self.model.unselectRoi(tag);
                else
                    self.model.selectRoi(tag);
                end
              case 'extend'
                % Assign ROI to current group
                self.model.assignRoiToCurrentGroup(tag);
                self.model.selectSingle(tag);
            end
        end
        
        function selectRoisByOverlay(self)
        % SELECTROISBYREGION Select multiple ROIs by drawing a region overlay
            self.view.setRoiVisibility(true);
            self.enableFreehandShortcut = false;
            if length(varargin) == 1
                overlay = images.roi.Freehand(self.view.guiHandles.roiAxes,...
                                             'Position', varargin{1});
            else
                overlay = drawfreehand(self.view.guiHandles.roiAxes);
            end
            
            if ~isempty(overlay.Position)
                self.model.selectRoisByOverlay(overlay);
            else
                disp('Empty Overlay. ROI selection not changed.')
            end
            delete(rawRoi)

            self.enableFreehandShortcut = true;
        end

        function enterMoveRoiMode(self)
        % ENTERMOVEROIMODE callback to enter moving mode of
        % selected ROIs
            if ~self.model.singleRoiSelected()
                error('Please select a single ROI to move!')
            end
            mainFig = self.view.guiHandles.mainFig;
            usrData = get(mainFig,'UserData');
            usrData.oldWindowButtonDownFcn = get(mainFig,'WindowButtonDownFcn');
            usrData.oldWindowKeyPressFcn = get(mainFig, ...
                                               'WindowKeyPressFcn');
            
            % Initialize moveit data
            currentRoiPatch = self.view.createMovableRoi();
            usrData.moveitData.originalXYData = {get(currentRoiPatch,'XData') get(currentRoiPatch,'YData')};
            
            set(mainFig,'WindowButtonDownFcn',@self.moveRoi_Callback);
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
                relativePos = usrData.moveitData.pos(1, 1:2);
                movedPatch = usrData.moveitData.currentHandle;
                pttag = movedPatch.Tag;
                roiTag = helper.convertTagToInd(pttag,'roi');
                self.model.moveRoi(roiTag, relativePos);
            end
            delete(usrData.moveitData.currentHandle);
            
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
            if roiFunc.isaRoiPatch(selectedObj)
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

        function toggleRoiVisibility(self)
            if self.view.roiVisible
                self.view.setRoiVisibility(false);
            else
                self.view.setRoiVisibility(true);
            end
        end

        function moveRoiKeyPressCallback(self,src,evnt)
            if isempty(evnt.Modifier) && strcmp(evnt.Key,'escape')
                selectedObj = gco;
                self.exitMoveRoiMode(selectedObj,'cancel');
            end
        end
        
        % Methods for contrast
        function contrastSlider_Callback(self,src,evnt)
        % Method to change contrast of map image
            contrastSliderInd = helper.convertTagToInd(src.Tag, ...
                                                       'contrastSlider');
            contrastLim = self.view.getContrastSlidertLim();
            dataLim = self.view.getContrastSliderDataLim();
            % Check whether contrastLim is valid (min < max), otherwise set the
            % other slider to a valid value based on the new value of
            % the changed slider;
            if contrastLim(1) >= contrastLim(2)
                contrastLim = self.calcMinLessThanMax(contrastSliderInd,...
                                                      contrastLim,dataLim);
                self.view.setContrastLim(contrastLim);
            end
            self.view.changeMapContrast(contrastLim);
            self.view.saveContrastLim(contrastLim);
        end
        
        function contrastLim = calcMinLessThanMax(self,contrastSliderInd,...
                                                  contrastLim,dataLim)
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
        


    end

end
