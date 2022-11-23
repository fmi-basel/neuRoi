classdef BaseTrialController < handle
    properties
        model
        view
        enableFreehandShortcut
    end
    
    methods
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
        
        function deleteSelectedRoi(self,src,evnt)
            answer=questdlg("Do you want to delete the roi only in the current trial or in all trials?","Roi deleting",...
                            'Current','All','Cancel');
            
            switch answer
              case 'Current'
                self.model.deleteRoiCurrent();
              case 'All'
                self.model.deleteRoiAll();
            end
            self.view.RoiSaveStatus('Rois have been changed and not saved','red');
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
            self.view.RoiSaveStatus('Rois have been changed and not saved','red');
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

        function toggleRoiVisibility(self)
            self.view.toggleRoiVisibility()
        end

        function moveRoiKeyPressCallback(self,src,evnt)
            if isempty(evnt.Modifier) && strcmp(evnt.Key,'escape')
                selectedObj = gco;
                self.exitMoveRoiMode(selectedObj,'cancel');
            end
        end

    end

end
