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
                  case 'q'
                    self.model.selectMapType(1)
                  case 'w'
                    self.model.selectMapType(2)
                  case 't'
                    self.toggleRoiVisibility()
                  case 'x'
                    self.replaceRoiByDrawing();
                  case 'v'
                    self.enterMoveRoiMode();
                  case {'d','delete','backspace'}
                    self.deleteSelectedRois();
                  case {'equal','2'}
                    self.view.zoomFcn(-1);
                  case {'hyphen','1'}
                    self.view.zoomFcn(1);
                end
            end
        end
        
        function addRoiByDrawing(self)
            self.model.roiVisible = true;
            self.enableFreehandShortcut = false;
            rawRoi = drawfreehand(self.view.guiHandles.roiAxes);
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
            selectedIdxs = self.model.roiArr.getSelectedIdxs();
            if length(selectedIdxs) == 1
                roi = self.model.roiArr.getSelectedRois();
                % Remove ROI in roiImg
                roiImgData = self.view.getRoiImgData();
                newRoiImgData = roi.addMaskToImg(roiImgData, 0);
                self.view.setRoiImgData(newRoiImgData);

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
                        self.model.updateRoiByIdx(selectedIdxs(1), freshRoi);
                        self.model.selectRoisByIdxs(selectedIdxs(1));
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
            self.view.RoiSaveStatus('Rois have been changed and not saved','red');
        end

        function selectRoi_Callback(self, src, evnt)
            currPt = get(self.view.guiHandles.roiAxes, 'CurrentPoint');
            % get Tag value under currPt
            roiImgData = self.view.getRoiImgData();
            tag = roiImgData(round(currPt(1,2)), round(currPt(1,1)));
            % select Roi accordingly
            if tag > 0
                self.roiClicked_Callback(tag);
            else
                if ~isempty(self.model.roiArr.getSelectedIdxs())
                    self.model.unselectAllRois();
                end
            end
        end

        function roiClicked_Callback(self, tag)
            selectionType = get(gcf,'SelectionType');
            switch selectionType
              case {'normal','alt'}
                self.model.selectRois([tag]);
              case 'extend'
                selectedTags = self.model.roiArr.getSelectedTags();
                if ismember(tag, selectedTags)
                    self.model.unselectRoi(tag);
                else
                    self.model.selectRoi(tag);
                end
            end
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
            self.view.RoiSaveStatus('Rois have been changed and not saved','red');
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

    end

end
