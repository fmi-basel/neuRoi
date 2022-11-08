classdef TrialStackController < handle
    properties
        model
        view

        enableFreehandShortcut
    end
    
    methods
        function self = TrialStackController(mymodel)
            self.model = mymodel;
            self.view = trialStack.TrialStackView(self.model,self);
            MaxTrialnumber = self.model.getMaxTrialnumber;
            self.view.setTrialNumberandSliderLim(1,[1,MaxTrialnumber]);
            self.view.displayCurrentMap();
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
            tempTrial = self.model.currentTrialIdx-round(evnt.VerticalScrollCount); % - to get the direction as i prefer it, JE
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
                  case 't'
                    self.toggleRoiVisibility()
                  case 'x'
                    self.replaceRoiByDrawing();
                  case 'v'
                    self.enterMoveRoiMode();
                  case {'d','delete','backspace'}
                    self.deleteSelectedRoi();
                end
            end
        end

        function RoiFileIdentifierEdit_Callback(self,src,evnt)
            self.model.roiFileIdentifier=src.String;
        end

        function SaveRoiNormal_Callback(self,src,evnt)
            self.model.SaveRoiNormal();
            self.view.RoiSaveStatus('Rois saved','green');
        end

        function ExportRois_Callback(self,src,evnt)
            self.model.ExportRois();
            self.view.RoiSaveStatus('Rois exported','green');
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
            newAlpha= self.view.getRoiAlphaSliderValue;
            self.view.setRoiImgAlpha(newAlpha);
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
