classdef TrialStackController < baseTrial.BaseTrialController
    methods
        function self = TrialStackController(mymodel)
            self.model = mymodel;
            self.view = trialStack.TrialStackView(self.model,self);
            self.view.setTrialNumberandSliderLim(1,[1,self.model.nTrial]);
            self.view.displayCurrentTrial();
            self.enableFreehandShortcut = true;
        end
        
        function keyPressCallback(self, src, evnt)
            keyPressCallback@baseTrial.BaseTrialController(self, src, evnt); %call base function
            if strcmp(evnt.Modifier,'control')
                switch evnt.Key
                  case 'b'
                    self.addRoisInStack();
                  case {'d','delete','backspace'}
                    self.deleteSelectedRoisInStack();
                end
            else
                switch evnt.Key
                  case {'j','k'}
                    self.slideTrialCallback(evnt)
                end
            end
        end
        
        function addRoisInStack(self, src, evnt)
        % TODO 2023-01-05
            self.model.addRoisInStack(self.model.roiGroupName);
            self.view.drawAllRoisOverlay();
        end
        
        function deleteSelectedRoisInStack(self, src, evnt)
            self.model.deleteSelectedRoisInStack();
            self.view.RoiSaveStatus('Rois have been changed and not saved','red');
        end
        
        function slideTrialCallback(self,evnt)
            if strcmp(evnt.Key, 'k')
                self.model.currentTrialIdx = min(self.model.currentTrialIdx+1, self.model.nTrial);
            elseif strcmp(evnt.Key, 'j')
                self.model.currentTrialIdx = max(self.model.currentTrialIdx-1, 1);
            end
            self.view.setTrialNumberSlider(self.model.currentTrialIdx);
        end
        
        function ScrollWheelFcnCallback(self, src, evnt)
        %JE-Mouswheelscroll functionality for scrolling trough the trials
        %TO DO: zoom function can casues problems and should be deactivated first
            tempTrial = self.model.currentTrialIdx-round(evnt.VerticalScrollCount); % - to get the direction as i prefer it, JE
            self.model.currentTrialIdx = tempTrial;
            self.view.setTrialNumberSlider(self.model.currentTrialIdx);
        end

        function RoiFileIdentifierEdit_Callback(self,src,evnt)
            self.model.roiFileIdentifier=src.String;
        end

        function saveRoiStack_Callback(self,src,evnt)
        % TODO make this work
            if self.model.roiFilePath
                self.model.saveRoiStack(self.model.roiFilePath);
            else
                defFileName = 'roiArrStack.mat';
                defFilePath = fullfile(self.model.roiDir, defFileName);
                [fileName, fileDir] = uiputfile('*.mat', 'Save ROIs stack', defFilePath);
                if fileName
                    self.model.roiDir = fileDir;
                    filePath = fullfile(fileDir, fileName);
                    self.model.saveRoiStack(filePath);
                end
            end
            % TODO indicate in GUI the non-saved status
            % self.view.RoiSaveStatus('Rois saved','green');
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
            newAlpha= self.view.getRoiAlphaSliderValue;
            self.view.setRoiImgAlpha(newAlpha);
        end
        
        function updateContrastForCurrentMap(self)
        % Set limit and values of the contrast sliders
            [dataLim, contrastLim] = self.model.getDataLimAndContrastLim();
            self.view.setDataLimAndContrastLim(dataLim, contrastLim);
            self.view.changeMapContrast(contrastLim);
        end
        
        function delete(self)
            if isvalid(self.view)
                self.view.deleteFigures();
                delete(self.view)
            end
            if isvalid(self.model)
                delete(self.model)
            end
        end
    end
end
