classdef TrialController < handle
    properties
        model
        view
        nMapMax
        enableFreehandShortcut
    end
    methods
        function self = TrialController(mymodel)
            self.model = mymodel;
            self.nMapMax = 6;
            self.view = TrialView(self.model,self);
            
            % Initialize map display
            self.view.toggleMapButtonValidity(self.model);
            self.view.displayCurrentMap();
            self.enableFreehandShortcut = true;
        end
        
        function keyPressCallback(self,src,evnt)
            if strcmp(src.Tag,'traceFig')
                disp('switch to main figure')
                figure(self.view.guiHandles.mainFig)
            end

            if isempty(evnt.Modifier)
                switch evnt.Key
                  case 'f'
                    if self.enableFreehandShortcut
                        self.addRoiByDrawing();
                    end
                  case {'d','delete','backspace'}
                    self.deleteSelectedRoi();
                  case 'r'
                    self.toggleRoiVisibility();
                  case 'q'
                    self.selectMap(1);
                  case 'w'
                    self.selectMap(2);
                  case 'e'
                    self.selectMap(3);
                  case 'v'
                    self.enterMoveRoiMode();
                  case 'x'
                    self.replaceRoiByDrawing();
                  case {'equal','2'}
                    self.view.zoomFcn(-1);
                  case {'hyphen','1'}
                    self.view.zoomFcn(1);
                end
            elseif strcmp(evnt.Modifier,'control')
                switch evnt.Key
                  case 'a'
                    self.selectAllRoi_Callback();
                  case 'q'
                    self.loadRoiArray();
                  case '1'
                    self.view.zoomReset();
                end
            end
        end
                        
        function selectMap(self,ind)
            self.model.selectMap(ind);
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
        function toggleRoiVisibility(self)
            if self.model.roiVisible
                self.model.roiVisible = false;
            else
                self.model.roiVisible = true;
            end
            % self.model.roiVisible = ~self.model.roiVisible;
        end
        
        function addRoiByDrawing(self)
            self.model.roiVisible = true;
            self.enableFreehandShortcut = false;
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
            self.enableFreehandShortcut = true;
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
        
        function selectAllRoi_Callback(self,src,evnt)
            self.model.selectAllRoi();
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
        
        function replaceRoiByDrawing(self)
            if length(self.model.selectedRoiTagArray) == 1
                % TODO at least dislay the edge!!
                self.view.changeRoiPatchColor('none','selected');
                roiTag = self.model.selectedRoiTagArray(1);
                figure(self.view.guiHandles.mainFig);
                self.enableFreehandShortcut = false;
                rawRoi = imfreehand;
                if ~isempty(rawRoi)
                    position = rawRoi.getPosition();
                    mapAxes = self.view.guiHandles.mapAxes;
                    if ~isempty(position)
                        self.model.updateRoi(roiTag,mapAxes,position);
                        self.model.selectSingleRoi(roiTag);
                    else
                        disp('Empty ROI. No replacement.')
                    end
                    delete(rawRoi)
                end
                self.enableFreehandShortcut = true;
                self.view.changeRoiPatchColor('default','selected');
            else
                error(['Exactly one ROI should be selected for ' ...
                       'replacing!']);
            end
        end
        
        
        % Functions for moving selected ROIs
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
        
        function deleteSelectedRoi(self)
            self.model.deleteSelectedRoi();
        end

        function saveRoiArray(self)
            if self.model.roiFilePath
                self.model.saveRoiArray(self.model.roiFilePath);
            else
                defFileName = [self.model.fileBaseName ...
                               '_RoiArray.mat'];
                defFilePath = fullfile(self.model.resultDir,defFileName);
                [fileName,fileDir] = uiputfile('*.mat','Save ROIs',defFilePath);
                if fileName
                    self.model.resultDir = fileDir;
                    filePath = fullfile(fileDir,fileName);
                    self.model.roiFilePath = filePath;
                    self.model.saveRoiArray(filePath);
                end
            end
        end
        
        function loadRoiArray(self)
            [fileName,fileDir] = uigetfile('*.mat','Load ROIs', ...
                                           self.model.resultDir);
            if fileName
                % Ask user whether to merge with existing ROIs or
                % replace the ROIs
                if length(self.model.roiArray)
                    answer = questdlg('How would you like to load new ROIs?', ...
                                      'Load ROIs', ...
                                      'Cancel','Merge','Replace', ...
                                      'Replace');
                    if strcmp(answer,'Cancel')
                        return
                    end
                    option = lower(answer);
                else
                    option = 'replace';
                end
                filePath = fullfile(fileDir,fileName)
                self.model.loadRoiArray(filePath,option);
            end
        end
        
        function syncTrace_Callback(self,source,evnt)
            self.setSyncTimeTrace(source.Value);
        end
        
        function setSyncTimeTrace(self,state)
            self.model.syncTimeTrace = state;
        end
        
        function setFigTagPrefix(self,prefix)
            self.view.setFigTagPrefix(prefix);
        end
        
        function raiseView(self)
            self.view.raiseFigures();
        end
        
        function traceFigClosed_Callback(self,src,evnt)
            if isvalid(self.view.guiHandles.mainFig)
                src.Visible = 'off';
            else
                delete(src)
            end
        end
        
        function mainFigClosed_Callback(self,src,evnt)
            delete(self.model);
            self.view.deleteFigures();
            delete(self.view);
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
