classdef TrialStackView < baseTrial.BaseTrialView
    properties
        contrastForAllTrial
    end
    
    methods
        function self = TrialStackView(mymodel,mycontroller,mytransformationParameter)
            self = self@baseTrial.BaseTrialView(mymodel, mycontroller);
            %self.previousTrialIdx=self.model.currentTrialIdx;
            self.mapSize = self.model.mapSize;
            self.guiHandles = trialStack.trialStackGui(self.model.mapSize);
            [funcDir, ~, ~]= fileparts(mfilename('fullpath'));
            neuRoiDir = fullfile(funcDir,'..');
            
            % Load customized color map
            cmapDir = fullfile(neuRoiDir,'colormap');
            mapCmapPath = fullfile(cmapDir,'clut2b.mat');
            try
                foo = load(mapCmapPath);
                self.mapColorMap = foo.clut2b;
            catch ME
                self.mapColorMap = 'default';
            end

            self.loadRoiColormap();
            self.contrastLimArray = cell(self.model.MAX_NUM_MAPS, self.model.nTrial);

            self.listenToModel();
            self.assignCallbacks();
            self.setRoiAlphaSlider(0.5);
            self.roiVisible = true;
            
            self.contrastForAllTrial = true;
        end
        
        function listenToModel(self)
            listenToModel@baseTrial.BaseTrialView(self); %call base function
            addlistener(self.model,'currentTrialIdx','PostSet',@self.displayCurrentTrial);
            addlistener(self.model,'mapType','PostSet',@(s,e) self.displayCurrentMap());
        end
        
        function assignCallbacks(self)
            assignCallbacks@baseTrial.BaseTrialView(self); %call base function
            set(self.guiHandles.RoiAlphaSlider,'Callback',...
                              @(s,e)self.controller.RoiAlphaSlider_Callback(s,e));
            set(self.guiHandles.TrialNumberSlider,'Callback',...
                              @(s,e)self.controller.TrialNumberSlider_Callback(s,e));
            set(self.guiHandles.EditCheckbox,'Callback',...
                              @(s,e)self.controller.EditCheckbox_Callback(s,e));
            set(self.guiHandles.saveRoiStackMenu,'Callback',...
                              @(s,e)self.controller.saveRoiStack_Callback(s,e));
            set(self.guiHandles.RoiFileIdentifierEdit,'Callback',...
                              @(s,e)self.controller.RoiFileIdentifierEdit_Callback(s,e));

        end
        
        function UpdateRoiFileIdentifier(self,src,evnt)
            set(self.guiHandles.RoiFileIdentifierEdit,'String',self.model.roiFileIdentifier);
        end

        function RoiSaveStatus(self, Text, Color)
            set(self.guiHandles.roiSavedStatus,'String',Text);
            set(self.guiHandles.roiSavedStatus,'BackgroundColor',Color);
        
        end

        function ChangePatchMode(self)
        
            if self.model.EditCheckbox
                self.deleteAllRoiAsOnePatch();
                self.redrawAllRoiPatch();
            else
                self.model.SaveCurrentRoiArrayInRoiArrays();
                self.model.unselectAllRoi();
                self.deleteAllRoiPatch();
                self.redrawAllRoiAsOnePatch();
            end
        
        end
        
        function changeRoiPatchColor(self,ptcolor,varargin)
            if nargin == 3
                if strcmp(ptcolor,'default')
                    ptcolor = self.DEFAULT_PATCH_COLOR;
                end
                for k=1:length(self.selectedRoiPatchArray)
                    roiPatch = self.selectedRoiPatchArray{k};
                    set(roiPatch,'Facecolor',ptcolor);
                end
            end
        end
        
        function roiPatch = findRoiPatchByTag(self,tag)
            ptTag = RoiFreehand.getPatchTag(tag);
            roiPatch = findobj(self.guiHandles.roiGroup,...
                               'Type','patch',...
                               'tag',ptTag);
            if isempty(roiPatch)
                error(sprintf('ROI #%d not found!',tag))
            end
        end

        function displayCurrentTrial(self,src,evnt)
            self.displayCurrentMap();
            self.drawAllRoisOverlay();
        end

        function displayTransformationData(self, TransformationParameter)
            TransformationStr=helper.deconvoluteStruct(TransformationParameter);
            TransformationStr=helper.deconvoluteStruct2Str(TransformationStr);
            set(self.guiHandles.TransformationListbox,'String',TransformationStr);
        end

        function displayTransformationName(self, TransformationName)
            set(self.guiHandles.mainFig,'Name',TransformationName);    
        end
        
        function plotMap(self,map)
            mapAxes = self.guiHandles.mapAxes;
            mapImage = self.guiHandles.mapImage;
            set(mapImage,'CData',map.data);
            cmap = self.mapColorMap;
            switch map.type
              case 'anatomy'
                colormap(mapAxes,gray);
              case 'response'
                colormap(mapAxes,cmap);
              otherwise
                colormap(mapAxes,'default');
            end
        end

        function displayError(self,errorStruct)
            self.guiHandles.errorDlg = errordlg(errorStruct.message,'TrialController');
        end

        function raiseFigures(self)
            mainFig = self.guiHandles.mainFig;
            % traceFig = self.guiHandles.traceFig;
            figure(mainFig)
        end
        
        % Methods for constrast
        function [dataLim, contrastLim] = getDataLimAndContrastLim(self)
            dataLim = self.model.getDataLim(self.contrastForAllTrial);
            
            mapTypeIdx = self.model.findMapTypeIdx(self.model.mapType);
            contrastLim = self.contrastLimArray{mapTypeIdx,self.model.currentTrialIdx};
            if isempty(contrastLim)
                contrastLim = dataLim;
            else
                ss = helper.rangeIntersect(dataLim,contrastLim);
                if ~isempty(ss)
                    contrastLim = ss;
                else
                    contrastLim = dataLim;
                end
            end
        end

        function saveContrastLim(self,contrastLim)
            mapTypeIdx = self.model.findMapTypeIdx(self.model.mapType);
            if self.contrastForAllTrial
                [self.contrastLimArray{mapTypeIdx,:}] = deal(contrastLim);
            else
                self.contrastLimArray{mapTypeIdx,self.model.currentTrialIdx} = contrastLim;
            end
        end
        
        %JE-Methods for changing Alpha values
        
        function setRoiImgAlpha(self,newAlpha)
            self.AlphaForRoiOnePatch = newAlpha;
            roiImgData = self.guiHandles.roiImg.CData;
            self.guiHandles.roiImg.AlphaData = (roiImgData > 0) * self.AlphaForRoiOnePatch;
        end

        function setRoiAlphaSlider(self,NewAlpha)
             set(self.guiHandles.RoiAlphaSlider ,'Value',NewAlpha);
        end

        function NewAlpha = getRoiAlphaSliderValue(self)
            NewAlpha=self.guiHandles.RoiAlphaSlider.Value;
        end
        
        %JE-Methods for changing trial via slider
        function setTrialNumberandSliderLim(self,Trialnumber,SliderLim)
            set(self.guiHandles.TrialNumberSlider ,'Min',SliderLim(1),'Max',SliderLim(2),...
                   'Value',Trialnumber, 'SliderStep',[1, 5]/(SliderLim(2)-SliderLim(1))); 
        end

        function setTrialNumberSlider(self,Trialnumber)
            set(self.guiHandles.TrialNumberSlider ,'Value',Trialnumber);
        end

        function setTrialSliderLim(self,SliderLim)
            set(self.guiHandles.TrialNumberSlider ,'Min',SliderLim(1),'Max',SliderLim(2), 'SliderStep',[1, 5]/(SliderLim(2)-SliderLim(1)));
        end

        function dataLim = getTrialSliderDataLim(self)
            dataLim(1) = self.guiHandles.TrialNumberSlider.Min;
            dataLim(2) = self.guiHandles.TrialNumberSlider.Max;
        end

        function Trialnumber = getTrialnumberSlider(self)
            Trialnumber=self.guiHandles.TrialNumberSlider.Value;
        end
        
        function deleteFigures(self)
            mainFig = self.guiHandles.mainFig;
            delete(mainFig);
        end

        function recordState(self)
            error('Not implemented!')
        end

        function restoreState(self)
            error('Not implemented!')
        end

    end
    
end
