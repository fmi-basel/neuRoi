classdef TrialStackView < BaseClasses.Base_trial_view
    properties
%         model
%         controller
%         guiHandles
%         mapColorMap
        
    end

    methods
        function self = TrialStackView(mymodel,mycontroller,mytransformationParameter)
            self.model = mymodel;
            self.controller = mycontroller;
            %self.previousTrialIdx=self.model.currentTrialIdx;
            self.mapSize = self.model.mapSize;
            self.guiHandles = trialStack.trialStackGui(self.model.mapSize);
            [neuRoiDir, ~, ~]= fileparts(mfilename('fullpath'));
            
            % Load customized color map
            cmapPath = fullfile(neuRoiDir, 'colormap', ...
                                'clut2b.mat');
            try
                foo = load(cmapPath);
                self.mapColorMap = foo.clut2b;
            catch ME
                self.mapColorMap = 'default';
            end

            self.listenToModel();
            self.assignCallbacks();
            self.setRoiAlphaSlider(0.5);

            % Save original settings for zoom
            self.zoom.origXLim = self.guiHandles.mapAxes.XLim;
            self.zoom.origYLim = self.guiHandles.mapAxes.YLim;
            self.zoom.maxZoomScrollCount = 30;
            self.zoom.scrollCount = 0;
            
            
            helper.imgzoompan(self.guiHandles.mapAxes,...
                   'ButtonDownFcn',@(s,e)self.controller.selectRoi_Callback(s,e),'ImgHeight',self.mapSize(1),'ImgWidth',self.mapSize(2));

        end
        
        function listenToModel(self)
            listenToModel@BaseClasses.Base_trial_view(self); %call base function
            addlistener(self.model,'currentTrialIdx','PostSet',@self.selectAndDisplayMap);
            addlistener(self.model,'mapType','PostSet',@self.selectAndDisplayMap);
            addlistener(self.model,'loadNewRois',@(~,~)self.redrawAllRoiPatch());
            addlistener(self.model,'roiUpdated',...
                        @self.updateRoiPatchPosition);
            addlistener(self.model,'roiSelected',...
                        @self.updateTimeTraceDisplay);
            addlistener(self.model,'roiUnSelected',...
                        @self.updateTimeTraceDisplay);
            addlistener(self.model,'roiSelectionCleared',...
                        @self.updateTimeTraceDisplay);
        end
        
        function assignCallbacks(self)
            assignCallbacks@BaseClasses.Base_trial_view(self); %call base function
%             set(self.guiHandles.mainFig,'WindowKeyPressFcn',...
%                               @(s,e)self.controller.keyPressCallback(s,e));
%             set(self.guiHandles.mainFig,'WindowScrollWheelFcn',...
%                               @(s,e)self.controller.ScrollWheelFcnCallback(s,e));
            set(self.guiHandles.contrastMinSlider,'Callback',...
                              @(s,e)self.controller.contrastSlider_Callback(s,e));
            set(self.guiHandles.contrastMaxSlider,'Callback',...
                              @(s,e)self.controller.contrastSlider_Callback(s,e));
            set(self.guiHandles.RoiAlphaSlider,'Callback',...
                              @(s,e)self.controller.RoiAlphaSlider_Callback(s,e));
            set(self.guiHandles.TrialNumberSlider,'Callback',...
                              @(s,e)self.controller.TrialNumberSlider_Callback(s,e));
            set(self.guiHandles.roiMenuEntry1,'Callback',...
                @(~,~)self.controller.enterMoveRoiMode())
            set(self.guiHandles.EditCheckbox,'Callback',...
                              @(s,e)self.controller.EditCheckbox_Callback(s,e));
            set(self.guiHandles.SaveRoiNormal,'Callback',...
                              @(s,e)self.controller.SaveRoiNormal_Callback(s,e));
            set(self.guiHandles.ExportRois,'Callback',...
                              @(s,e)self.controller.ExportRois_Callback(s,e));


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
       
        function updateRoiPatchSelection(self,src,evnt)
            newTagArray = evnt.AffectedObject.selectedRoiTagArray;
            for k=1:length(self.selectedRoiPatchArray)
                roiPatch = self.selectedRoiPatchArray{k};
                roiPatch.Selected = 'off';
                roiTag = helper.convertTagToInd(roiPatch.Tag,'roi');
                self.removeRoiTagText(roiTag);
            end
            self.selectedRoiPatchArray = {};
            for k=1:length(newTagArray)
                tag = newTagArray(k);
                roiPatch = self.findRoiPatchByTag(tag);
                roiPatch.Selected = 'on';
                self.displayRoiTag(roiPatch);
                uistack(roiPatch,'top') % bring the selected roi
                                        % patch to front of the
                                        % image and number tag
                self.selectedRoiPatchArray{k} = roiPatch;
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

        function updateRoiPatchPosition(self,src,evnt)
            updRoiArray = evnt.roiArray;
            for k=1:length(updRoiArray)
                roi = updRoiArray(k);
                roiPatch = self.findRoiPatchByTag(roi.tag);
                roi.updateRoiPatchPos(roiPatch);
            end
        end
        
        function selectAndDisplayMap(self,src,evnt)

            self.displayCurrentMap();
        end
        
        function displayCurrentMap(self)
            map = self.model.getCurrentMap();
            self.plotMap(map);
            self.displayMeta(map.meta);
            self.controller.updateContrastForCurrentMap();
            if self.model.EditCheckbox
                self.model.SaveRoiArrayInRoiArrays();
                self.model.unselectAllRoi();
                self.redrawAllRoiPatch();
            else
                self.redrawAllRoiAsOnePatch();
            end
%             self.previousTrialIdx=self.model.currentTrialIdx;
        end
        
        function displayMeta(self,meta)
            metaStr = helper.convertOptionToString(meta);
            set(self.guiHandles.metaText,'String',metaStr);
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
        
        function deleteFigures(self)
            mainFig = self.guiHandles.mainFig;
            traceFig = self.guiHandles.traceFig;
            delete(mainFig);
            delete(traceFig);
        end

        %JE-Methods for changing Alpha values

        function setRoiAlphaSlider(self, NewAlpha)
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



        % Methods for changing contrast
        function changeMapContrast(self,contrastLim)
        % Usage: myview.changeMapContrast(contrastLim), contrastLim
        % is a 1x2 array [cmin cmax]
            caxis(self.guiHandles.mapAxes,contrastLim);
        end


        function setDataLimAndContrastLim(self,dataLim,contrastLim)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                cs = contrastSliderArr(end+1-k);
                set(cs,'Min',dataLim(1),'Max',dataLim(2),...
                       'Value',contrastLim(k));
            end
        end

        function dataLim = getContrastSliderDataLim(self)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            dataLim(1) = contrastSliderArr(1).Min;
            dataLim(2) = contrastSliderArr(1).Max;
        end

        function setContrastSliderDataLim(self,dataLim)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastSliderArr(end+1-k).Min = dataLim(1);
                contrastSliderArr(end+1-k).Max = dataLim(2);
            end
        end

        function contrastLim = getContrastLim(self)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastLim(k) = contrastSliderArr(end+1-k).Value;
            end
        end

        function setContrastLim(self,contrastLim)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastSliderArr(end+1-k).Value = contrastLim(k);
            end
        end
    end
    
end