classdef TrialController < baseTrial.BaseTrialController
    properties
        nMapMax
    end
    
    methods
        function self = TrialController(mymodel)
            self.model = mymodel;
            self.nMapMax = 6;
            self.view = trialMvc.TrialView(self.model,self);
            
            % Initialize map display
            self.view.toggleMapButtonValidity(self.model);
            self.view.displayCurrentMap();
            self.enableFreehandShortcut = true;
        end
        
        function keyPressCallback(self,src,evnt)
            keyPressCallback@baseTrial.BaseTrialController(self, src, evnt); %call base function
            if strcmp(src.Tag,'traceFig')
                disp('switch to main figure')
                figure(self.view.guiHandles.mainFig)
            end

            if isempty(evnt.Modifier)
                switch evnt.Key
                  case {'d','delete','backspace'}
                    self.deleteSelectedRoi();
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
                end
            elseif strcmp(evnt.Modifier,'control')
                switch evnt.Key
                  case 'a'
                    self.selectAllRoi_Callback();
                  % case 'q'
                  %   self.loadRoiArray();
                  case '1'
                    self.view.zoomReset();
                end
            end
        end

        function removeOverlapRoiMenuCallback(self)
            self.model.removeRoiOverlap();
        end
                        
        function selectMap(self,ind)
            self.model.selectMap(ind);
        end
        
        function mapButtonSelected_Callback(self,src,evnt)
            tag = evnt.NewValue.Tag;
            ind = helper.convertTagToInd(tag,'mapButton');
            self.model.selectMap(ind);
        end
        
        function importMapCallback(self,src,evnt)
            [fileName,fileDir] = uigetfile('*.tif','Import map from file');
            if fileName
                filePath = fullfile(fileDir,fileName);
                self.model.importMap(filePath)
            end
        end
        
        % Methods for ROI based processing
        function selectAllRoi_Callback(self,src,evnt)
            self.model.selectAllRoi();
        end
        
        % Functions for moving selected ROIs
        function deleteSelectedRoi(self)
            self.model.deleteSelectedRoi();
        end

        function saveRoiArray(self)
            if self.model.roiFilePath
                self.model.saveRoiArray(self.model.roiFilePath);
            else
                defFileName = [self.model.fileBaseName ...
                               '_RoiArray.mat'];
                defFilePath = fullfile(self.model.roiDir,defFileName);
                [fileName,fileDir] = uiputfile('*.mat','Save ROIs',defFilePath);
                if fileName
                    self.model.roiDir = fileDir;
                    filePath = fullfile(fileDir,fileName);
                    self.model.roiFilePath = filePath;
                    self.model.saveRoiArray(filePath);
                end
            end
        end
        
        function loadRoiArray(self)
            [fileName,fileDir] = uigetfile('*.mat','Load ROIs', ...
                                           self.model.roiDir);
            if fileName
                % Load RoiArray will overwrite ROIs that already exists
                % Ask user to confirm
                if length(self.model.roiArr.getRoiList())
                    answer = questdlg('Existing ROIs will be deleted. Would you like to proceed?', ...
                                      'Load ROIs', ...
                                      'No','Yes', ...
                                      'No');
                    if strcmp(answer,'No')
                        return
                    end
                end
                option = 'replace';
                filePath = fullfile(fileDir,fileName)
                self.model.loadRoiArray(filePath,option);
            end
        end

        function importRoisFromImageJ(self)
            [fileName,fileDir] = uigetfile('*.mat','Import ROIs from ImageJ', ...
                                           self.model.jroiDir);
            if fileName
                option = 'replace';
                filePath = fullfile(fileDir,fileName)
                self.model.importRoisFromImageJ(filePath);
            end
        end

        function importRoisFromMask(self)
            [fileName,fileDir] = uigetfile('*.tif','Import ROIs from mask', ...
                                           self.model.maskDir);
            if fileName
                option = 'replace';
                filePath = fullfile(fileDir,fileName)
                self.model.importRoisFromMask(filePath);
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