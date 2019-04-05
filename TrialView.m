classdef TrialView < handle
    properties
        model
        controller
        guiHandles
    end
    
    properties (Constant)
        DEFAULT_PATCH_COLOR = 'red'
    end
    
    methods
        function self = TrialView(mymodel,mycontroller)
            self.model = mymodel;
            self.controller = mycontroller;
            
            mapSize = self.model.getMapSize();
            self.guiHandles = trialGui(mapSize);
            

            self.displayTitle();
            self.displayMeta();
            self.changeTraceFigVisibility();
            
            self.listenToModel();
            self.assignCallbacks();
        end
        
        function listenToModel(self)
            addlistener(self.model,'currentMapInd','PostSet',@self.selectAndDisplayMap);
            addlistener(self.model,'mapArrayLengthChanged',@self.toggleMapButtonValidity);
            addlistener(self.model,'mapUpdated',...
                        @self.updateMapDisplay);
            
            addlistener(self.model,'roiVisible','PostSet',...
                        @self.changeRoiVisibility);
            addlistener(self.model,'roiAdded',@self.drawLastRoiPatch);
            addlistener(self.model,'selectedRoiTagArray','PostSet',...
                        @self.updateRoiPatchSelection);
            addlistener(self.model,'roiDeleted',...
                        @self.deleteRoiPatch);
            addlistener(self.model,'roiUpdated',...
                        @self.updateRoiPatchPosition);
            addlistener(self.model,'roiArrayReplaced',...
                        @(~,~)self.redrawAllRoiPatch());
            
            addlistener(self.model,'syncTimeTrace','PostSet',...
                        @(~,~)self.changeTraceFigVisibility());
            addlistener(self.model,'roiSelected',...
                        @self.updateTimeTraceDisplay);
            addlistener(self.model,'roiUnSelected',...
                        @self.updateTimeTraceDisplay);
            addlistener(self.model,'roiSelectionCleared',...
                        @self.updateTimeTraceDisplay);
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.mapButtonGroup,'SelectionChangedFcn', ...
               @(s,e)self.controller.mapButtonSelected_Callback(s,e));
            set(self.guiHandles.mainFig,'CloseRequestFcn',...
               @(s,e)self.controller.mainFigClosed_Callback(s,e));
            set(self.guiHandles.contrastMinSlider,'Callback',...
               @(s,e)self.controller.contrastSlider_Callback(s,e));
            set(self.guiHandles.contrastMaxSlider,'Callback',...
               @(s,e)self.controller.contrastSlider_Callback(s,e));
            
            set(self.guiHandles.mainFig,'WindowButtonDownFcn',...
                @(s,e)self.controller.selectRoi_Callback(s,e));

            set(self.guiHandles.roiMenuEntry1,'Callback',...
                @(~,~)self.controller.enterMoveRoiMode())
            
            set(self.guiHandles.mainFig,'WindowKeyPressFcn', ...
                @(s,e)self.controller.keyPressCallback(s,e));
            
            set(self.guiHandles.saveRoiMenu,'Callback',...
                @(~,~)self.controller.saveRoiArray());
            set(self.guiHandles.loadRoiMenu,'Callback',...
                @(~,~)self.controller.loadRoiArray());
            
            set(self.guiHandles.traceFig,'WindowKeyPressFcn',...
                @(s,e)self.controller.keyPressCallback(s,e));
            set(self.guiHandles.traceFig,'CloseRequestFcn', ...
                @(s,e)self.controller.traceFigClosed_Callback(s,e));
        end
        
        function displayTitle(self)
            set(self.guiHandles.mainFig,'Name', ...
                              self.model.name);
            set(self.guiHandles.traceFig,'Name', ...
                              [self.model.name '_time_trace']);
            ttag = ['trial_' self.model.tag];
            set(self.guiHandles.mainFig,'Tag',[ttag '_main_fig']);
            set(self.guiHandles.traceFig,'Tag',[ttag '_time_trace']);
        end
        function displayMeta(self)
            meta = self.model.meta;
            metaStr = TrialView.convertOptionToString(meta);
            set(self.guiHandles.metaText,'String',metaStr);
        end
        
        % Methods for displaying maps
        function selectAndDisplayMap(self,src,evnt)
            obj = evnt.AffectedObject;
            ind = obj.currentMapInd;
            self.selectMapButton(ind);
            self.displayCurrentMap();
        end
        
        function toggleMapButtonValidity(self,src,evnt)
            nActiveButton = src.getMapArrayLength();
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            for k=1:length(mapButtonArray)
                mb = mapButtonArray(end+1-k);
                if k <= nActiveButton
                    mb.Enable = 'on';
                else
                    mb.Enable = 'off';
                end
            end
        end

        function updateMapDisplay(self,src,evnt)
            currInd = src.currentMapInd;
            updatedInd = evnt.ind;
            if currInd == updatedInd
                self.displayCurrentMap();
            end
        end
        
        function selectMapButton(self,ind)
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            mapButtonGroup.SelectedObject = mapButtonArray(end+1-ind);
        end
            
        function displayCurrentMap(self)
            map = self.model.getCurrentMap();
            self.showMapOption(map);
            self.plotMap(map);
            self.controller.updateContrastForCurrentMap();
        end
        
        function showMapOption(self,map)
            optionStr = TrialView.convertOptionToString(map.option);
            self.guiHandles.mapOptionText.String = optionStr;
        end
        
        function plotMap(self,map)
            mapAxes = self.guiHandles.mapAxes;
            mapImage = self.guiHandles.mapImage;
            set(mapImage,'CData',map.data);
            switch map.type
              case 'anatomy'
                colormap(mapAxes,gray);
              case 'response'
                colormap(mapAxes,'default');
              case 'responseMax'
                colormap(mapAxes,'default');
              case 'localCorrelation'
                colormap(mapAxes,'default');
              case 'import'
                colormap(mapAxes,gray);
              otherwise
                colormap(mapAxes,'default');
            end
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
        
        % Methods for ROI based processing
        function drawLastRoiPatch(self,src,evnt)
            roi = src.getRoiByTag('end');
            self.addRoiPatch(roi);
        end
        
        function redrawAllRoiPatch(self)
            self.deleteAllRoiPatch();
            roiArray = self.model.getRoiArray();
            arrayfun(@(x) self.addRoiPatch(x),roiArray);
        end
        
        function addRoiPatch(self,roi)
            roiPatch = roi.createRoiPatch(self.guiHandles.mapAxes, ...
                                          self.DEFAULT_PATCH_COLOR);
            % Add context menu for right click
            roiPatch.UIContextMenu = self.guiHandles.roiMenu;
        end
        
        function updateRoiPatchSelection(self,src,evnt)
            tagArray = evnt.AffectedObject.selectedRoiTagArray;
            roiPatchArray = self.getRoiPatchArray();
            for k=1:length(roiPatchArray)
                roiPatch = roiPatchArray(k);
                ptTag = get(roiPatch,'Tag');
                roiTag = helper.convertTagToInd(ptTag,'roi');
                if ismember(roiTag,tagArray)
                    roiPatch.Selected = 'on';
                else
                    roiPatch.Selected = 'off';
                end
            end
        end
        
        function changeRoiPatchColor(self,ptcolor,varargin)
            if nargin == 3
                if strcmp(ptcolor,'default')
                    ptcolor = self.DEFAULT_PATCH_COLOR;
                end
                roiPatchArray = self.getRoiPatchArray();
                if strcmp(varargin{1},'selected')
                    for k=1:length(roiPatchArray)
                        roiPatch = roiPatchArray(k);
                        if strcmp(roiPatch.Selected,'on')
                            set(roiPatch,'Facecolor',ptcolor);
                        end
                    end
                end
            end
        end
        
        function updateRoiPatchPosition(self,src,evnt)
            updRoi = evnt.roi;
            roiPatchArray = self.getRoiPatchArray();
            for k=1:length(roiPatchArray)
                roiPatch = roiPatchArray(k);
                ptTag = get(roiPatch,'Tag');
                roiTag = helper.convertTagToInd(ptTag,'roi');
                if isequal(roiTag,updRoi.tag)
                    updRoi.updateRoiPatchPos(roiPatch);
                end
            end
        end
        
        function roiPatchArray = getRoiPatchArray(self)
            mapAxes = self.guiHandles.mapAxes;
            children = mapAxes.Children;
            patchInd = arrayfun(@RoiFreehand.isaRoiPatch,children);
            roiPatchArray = children(patchInd);
        end
        
        function deleteAllRoiPatch(self)
            roiPatchArray = self.getRoiPatchArray();
            arrayfun(@(x) delete(x), roiPatchArray);
        end

        function deleteRoiPatch(self,src,evnt)
            tagArray = evnt.tagArray;
            roiPatchArray = self.getRoiPatchArray();
            for k=1:length(roiPatchArray)
                roiPatch = roiPatchArray(k);
                ptTag = get(roiPatch,'Tag');
                roiTag = helper.convertTagToInd(ptTag,'roi');
                if ismember(roiTag,tagArray)
                    delete(roiPatch);
                end
            end
        end
        
        function changeRoiVisibility(self,src,evnt)
            if self.model.roiVisible
                roiState = 'on';
            else
                roiState = 'off';
            end
            roiPatchArray = self.getRoiPatchArray();
            arrayfun(@(x) set(x,'Visible',roiState), roiPatchArray);
        end
        
        
        % Methods for displaying time traces
        function updateTimeTraceDisplay(self,src,evnt)
            if self.model.syncTimeTrace
                switch evnt.EventName
                  case 'roiSelected'
                    tag = evnt.tag;
                    [timeTrace,timeVec] = self.model.getTimeTraceByTag(tag,true);
                    self.plotTimeTrace(timeVec,timeTrace,tag);
                  case 'roiUnSelected'
                    tag = evnt.tag;
                    lineTag = sprintf('trace_%04d',tag);
                    hline = findobj(self.guiHandles.traceAxes,'Tag',lineTag);
                    delete(hline)
                  case 'roiSelectionCleared'
                    cla(self.guiHandles.traceAxes)
                    hold(self.guiHandles.traceAxes,'on')
                end
            end
            figure(self.guiHandles.mainFig)
        end
        
        function hline = plotTimeTrace(self,timeVec,timeTrace,tag)
            lineTag = sprintf('trace_%04d',tag);
            figure(self.guiHandles.traceFig)
            hline = plot(self.guiHandles.traceAxes,timeVec,...
                         timeTrace,...
                         'Tag',lineTag);
        end
        
        function changeTraceFigVisibility(self);
            if self.model.syncTimeTrace
                set(self.guiHandles.traceFig,'Visible','on');
            else
                set(self.guiHandles.traceFig,'Visible','off');
            end
            figure(self.guiHandles.mainFig)
        end
        
        % function setFigTagPrefix(self,prefix)
        %     mainFig = self.guiHandles.mainFig;
        %     traceFig = self.guiHandles.traceFig;
        %     mainFigTag = mainFig.Tag;
        %     set(mainFig,'Tag',[prefix '_' mainFigTag])
        %     traceFigTag = traceFig.Tag;
        %     set(traceFig,'Tag',[prefix '_' traceFigTag])
        % end

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
    end
    
    methods (Static)
        function optionStr = convertOptionToString(option)
            nameArray = fieldnames(option);
            stringArray = {};
            for i = 1:length(nameArray)
                name = nameArray{i};
                value = option.(name);
                stringArray{i} = sprintf('%s: %s',name,mat2str(value));
            end
            optionStr = [sprintf(['%s; '],stringArray{1:end-1}), ...
                         stringArray{end}];
                
        end
    end
end
