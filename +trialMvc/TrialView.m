classdef TrialView < baseTrial.BaseTrialView
    properties
        contrastLimArray
    end
    
    methods
        function self = TrialView(mymodel,mycontroller)
            self = self@baseTrial.BaseTrialView(mymodel, mycontroller);
            
            self.mapSize = self.model.getMapSize();
            self.guiHandles = trialMvc.trialGui(self.mapSize);
            

            self.displayTitle();
            self.displayMeta();
            self.changeTraceFigVisibility();
            
            set(self.guiHandles.syncTraceCheckbox,'Value', ...
                              self.model.syncTimeTrace)
            
            self.listenToModel();
            self.assignCallbacks();
            [neuRoiDir, ~, ~]= fileparts(mfilename('fullpath'));
            cmapPath = fullfile(neuRoiDir, 'colormap', ...
                                'clut2b.mat');
            try
                foo = load(cmapPath);
                self.mapColorMap = foo.clut2b;
            catch ME
                self.mapColorMap = 'default';
            end
            
            num_map = self.model.getMapArrayLength();
            self.contrastLimArray = cell(1,num_map);
            
            self.loadRoiColormap();
            self.roiVisible = true;
            self.drawAllRoisOverlay();
            
        end
        
        function listenToModel(self)
            listenToModel@baseTrial.BaseTrialView(self); %call base function
            addlistener(self.model,'currentMapInd','PostSet',@self.selectAndDisplayMap);
            addlistener(self.model,'mapAdded',@self.addMapView);
            addlistener(self.model,'mapUpdated',...
                        @self.updateMapDisplay);
            
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
            assignCallbacks@baseTrial.BaseTrialView(self); %call base function
            set(self.guiHandles.mapButtonGroup,'SelectionChangedFcn', ...
               @(s,e)self.controller.mapButtonSelected_Callback(s,e));
            set(self.guiHandles.mainFig,'CloseRequestFcn',...
               @(s,e)self.controller.mainFigClosed_Callback(s,e));
            
            set(self.guiHandles.roiMenuEntry1,'Callback',...
                @(~,~)self.controller.enterMoveRoiMode())
            
            set(self.guiHandles.saveRoiMenu,'Callback',...
                @(~,~)self.controller.saveRoiArray());
            set(self.guiHandles.loadRoiMenu,'Callback',...
                @(~,~)self.controller.loadRoiArray());
            set(self.guiHandles.importRoisFromImageJMenu,'Callback',...
                              @(~,~)self.controller.importRoisFromImageJ());
            set(self.guiHandles.importRoisFromMaskMenu,'Callback',...
                              @(~,~)self.controller.importRoisFromMask());

            set(self.guiHandles.importMapMenu,'Callback',...
                @(~,~)self.controller.importMapCallback());
            set(self.guiHandles.removeOverlapRoiMenu,'Callback',...
                @(~,~)self.controller.removeOverlapRoiMenuCallback());

            set(self.guiHandles.traceFig,'WindowKeyPressFcn',...
                @(s,e)self.controller.keyPressCallback(s,e));
            set(self.guiHandles.traceFig,'CloseRequestFcn', ...
            @(s,e)self.controller.traceFigClosed_Callback(s,e));
            
            set(self.guiHandles.syncTraceCheckbox,'Callback',...
            @(s,e)self.controller.syncTrace_Callback(s,e));
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
            metaStr = trialMvc.TrialView.convertOptionToString(meta);
            set(self.guiHandles.metaText,'String',metaStr);
        end

        %Mehtod for setup parameters when loading maps from file
        function SetupParaAfterMapsLoaded(self, NewMapsize)
            self.mapSize = NewMapsize;
            self.guiHandles.mapAxes.YLim=[0 NewMapsize(1)];
            self.guiHandles.mapAxes.XLim=[0 NewMapsize(2)];
            self.zoom.origXLim = self.guiHandles.mapAxes.XLim;
            self.zoom.origYLim = self.guiHandles.mapAxes.YLim;
            self.zoom.maxZoomScrollCount = 30;
            self.zoom.scrollCount = 0;
        end
        
        % Methods for displaying maps
        function selectAndDisplayMap(self,src,evnt)
            obj = evnt.AffectedObject;
            ind = obj.currentMapInd;
            self.selectMapButton(ind);
            self.displayCurrentMap();
        end
        
        function addMapView(self,src,event)
            self.toggleMapButtonValidity(self, src, evnt)
            self.contrastLimArray{end+1} = [];
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
              case 'responseMax'
                colormap(mapAxes,cmap);
              case 'localCorrelation'
                colormap(mapAxes,cmap);
              case 'import'
                colormap(mapAxes,gray);
              otherwise
                colormap(mapAxes,cmap);
            end
        end
        
        % Methods for ROIs
        function redrawAllRoiPatch(self)
            self.deleteAllRoiPatch();
            roiArray = self.model.getRoiArray();
            arrayfun(@(x) self.addRoiPatch(x),roiArray);
        end
        
        function displayRoiTag(self,roiPatch)
            ptTag = get(roiPatch,'Tag');
            tag = helper.convertTagToInd(ptTag,'roi');
            pos = roiPatch.Vertices(1,:);
            htext = text(self.guiHandles.roiGroup,pos(1),pos(2), ...
                         num2str(tag),'FontSize',8,'Color','m');
            htext.Tag = sprintf('roiTag_%d',tag);
        end
        
        function removeRoiTagText(self,roiTag)
            txtTag = sprintf('roiTag_%d',roiTag);
            htext = findobj(self.guiHandles.roiGroup,...
                               'Type','text',...
                               'Tag',txtTag);
            delete(htext);
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

        function changeRoiPatchTag(self,src,evnt)
            oldTag = evnt.oldTag;
            newTag = evnt.newTag;
            roiPatch = self.findRoiByTag(evnt.oldTag);
            roiPatch.tag = RoiFreehand.getPatchTag(newTag);
        end
        
        
        function roiPatchArray = getRoiPatchArray(self)
            mapAxes = self.guiHandles.roiGroup;
            children = mapAxes.Children;
            patchInd = arrayfun(@RoiFreehand.isaRoiPatch,children);
            roiPatchArray = children(patchInd);
        end
        
        function deleteAllRoiPatch(self)
            roiPatchArray = self.getRoiPatchArray();
            arrayfun(@(x) delete(x), roiPatchArray);
        end

        function changeRoiVisibility(self,src,evnt)
            if self.model.roiVisible
                roiState = 'on';
            else
                roiState = 'off';
            end
            set(self.guiHandles.roiGroup,'Visible',roiState);
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
        
        function changeTraceFigVisibility(self)
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
        
        % Methods for contrast
        function saveContrastLim(self,contrastLim)
            mapIdx = self.model.currentMapInd;
            self.contrastLimArray{mapIdx} = contrastLim;
        end
        
        function contrastLim = getContrastLim(self, dataLim)
            mapIdx = self.model.currentMapInd;

            contrastLim = self.contrastLimArray{mapIdx};
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
        
        function zoomReset(self)
            axish = gca;
            axish.XLim = self.zoom.origXLim;
            axish.YLim = self.zoom.origYLim;
            self.zoom.scrollCount = 0;
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