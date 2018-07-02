classdef NrView < handle
    properties
        model
        controller
        
        guiHandles
        currentMapName
        currentRoiPatch
        contrastLimStc
        unselectedRoiColor
    end
    
    methods
        function self = NrView(controller)
            self.controller = controller;
            self.model = controller.model;
            self.guiHandles = neuRoiGui();
            self.guiHandles.mainFig.Name = self.model.fileBaseName;
            self.guiHandles.traceFig.Name = [self.model.fileBaseName, ...
                   '_time_trace'];
            self.guiHandles.mapImage  = imagesc(self.model.anatomyMap,'Parent', ...
                                                self.guiHandles.mapAxes);

            self.unselectedRoiColor = 'red';

            self.assignCallbacks();
            self.addListners();
            
            self.plotMap('anatomy');
            self.currentMapName = 'anatomy';
            self.contrastLimStc = self.initContrastLimStc();
        end
        
        function contrastLimStc = initContrastLimStc(self)
            contrastLimStc.anatomy = minMax(self.model.anatomyMap);
            contrastLimStc.response = ...
                minMax(self.model.responseMap);
        end
                
        function addListners(self)
            addlistener(self.model,'responseMap','PostSet', ...
                        @(src,event)NrView.updateMapDisplay(self,src,event));

            % addlistener(self.model,'currentRoi','PostSet', ...
            %             @(src,event)NrView.updateCurrentRoiDisplay(self,src,event));
            
            % addlistener(self.model,'currentTimeTrace','PostSet', ...
            %             @(src,event)NrView.plotTimeTrace(self,src, ...
            %                                              event));

            % TODO
            % addlistener(self.controller,'timeTraceState','PostSet', ...
            %             @(src,event)NrView.plotTimeTrace(self,src, ...
            %                                              event));

            addlistener(self.controller,'roiDisplayState','PostSet', ...
                        @(src,event)NrView.toggleRoiDisplay(self,src, ...
                                                         event));

            % Listen to mapImage CData and update contrast slider limits
            addlistener(self.guiHandles.mapImage,'CData','PostSet', ...
                        @(src,event)NrView.updateContrastSliders(self,src,event));
            
            % Listen to contrast slider value and update mapImage
            % color map (caxis)
            addlistener(self.guiHandles.contrastMinSlider,'Value','PostSet',...
                        @(src,event)NrView.adjustContrast(self,src,event));
            addlistener(self.guiHandles.contrastMaxSlider,'Value','PostSet',...
                        @(src,event)NrView.adjustContrast(self,src,event));
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.anatomyButton,'Callback',...
                @(src,event)self.switchMap_Callback('anatomy'));
            set(self.guiHandles.responseButton,'Callback',...
                @(src,event)self.switchMap_Callback('response'));
            set(self.guiHandles.addRoiButton,'Callback',...
                @(src,event)self.addRoi_Callback(src,event));
            % set(self.gui,'CloseRequestFcn',@(src,event)...
            %              self.controller.closeGUI(src,event));
            set(self.guiHandles.mainFig,'WindowKeyPressFcn', ...
                              @(src,event)self.keyPressCallback(src,event));
            
            set(self.guiHandles.traceFig,'WindowKeyPressFcn',@(src,event)...
                         self.keyPressCallback(src,event));
            set(self.guiHandles.mainFig,'WindowButtonDownFcn',...
                @(src,event)self.selectRoi_Callback(src,event));
            set(self.guiHandles.traceFig,'CloseRequestFcn', ...
                              @(src,event)self.closeTraceFig(src, ...
                                                             event));
            
        end
                
    end

    % Callback functions
    methods
        function switchMap_Callback(self,newMapName)
            if ~strcmp(self.currentMapName,newMapName)
                currentContrastLim = self.getCurrentContrastLim();
                self.contrastLimStc = setfield(self.contrastLimStc, ...
                                               self.currentMapName,currentContrastLim);
                self.currentMapName = newMapName;
                self.plotMap(newMapName);
                contrastLim = getfield(self.contrastLimStc,self.currentMapName);
                self.setCurrentContrastLim(contrastLim);
            end
        end
        
        function addRoi_Callback(self,src,event)
            self.controller.addRoiInteract();
        end
        
        function selectRoi_Callback(self,src,event)
            selectionType = get(gcf,'SelectionType')
            if strcmp(selectionType,'normal')
                self.controller.selectSingleRoi();
            elseif strcmp(selectionType,'alt') % Ctrl pressed
                self.controller.selectMultRoi();
            end
        end
        
        function deleteRoi_Callback(self,src,event)
            self.controller.deleteRoi();
        end
        
        function keyPressCallback(self,src,event)
            if strcmp(src.Tag,'traceFig')
                figure(self.guiHandles.mainFig)
            end
            keyword = event.Key;
            switch keyword
              case 'q'
                self.switchMap_Callback('anatomy')
              case 'w'
                self.switchMap_Callback('response')
              case 'r'
                self.controller.toggleRoiDisplayState()
              case 'f'
                self.addRoi_Callback()
              case 'd'
                self.deleteRoi_Callback()
            end
        end
        
        function closeMainFig(self,src,event)
        % TODO
        end
        
        function closeTraceFig(self,src,event)
            if isvalid(self.guiHandles.mainFig)
                src.Visible = 'off';
            else
                delete(src)
            end
        end
    end

    methods
        function plotMap(self,mapName)
            hMapImage = self.guiHandles.mapImage;
            if ~isvalid(hMapImage)
                hMapImage = imagesc(self.model.anatomyMap,'Parent', ...
                                    self.guiHandles.mapAxes);
                self.guiHandles.mapImage = hMapImage;
            end

            switch mapName
              case 'anatomy'
                set(hMapImage,'CData',self.model.anatomyMap);
                colormap gray;
              case 'response'
                set(hMapImage,'CData',self.model.responseMap)
                colormap default
              case 'masterResponse'
                set(hMapImage,'CData',self.model.masterResponseMap)
              case 'localCorr'
                set(hMapImage,'CData',self.model.localCorrMap)
            end
        end

        function contrastLim = getCurrentContrastLim(self)
            minSliderVal = get(self.guiHandles.contrastMinSlider, ...
                               'Value');
            maxSliderVal = get(self.guiHandles.contrastMaxSlider, ...
                               'Value');
            contrastLim = [minSliderVal,maxSliderVal];
        end
        
        function setCurrentContrastLim(self,contrastLim)
            set(self.guiHandles.contrastMinSlider,'Value',contrastLim(1));
            set(self.guiHandles.contrastMaxSlider,'Value',contrastLim(2));
        end
        
        % Methods for viewing ROIs
        function roiPatch = addRoiPatch(self,roi)
            roiPatch = createRoiPatch(roi,self.guiHandles.mapAxes, ...
                           self.unselectedRoiColor);
        end
        
        function selectRoiPatch(self,roiPatch)
            roiPatch.Selected = 'on';
        end
        
        function unselectRoiPatch(self,roiPatch)
            roiPatch.Selected = 'off';
        end
        
        function selectSingleRoiPatch(self,slRoiPatch)
            slTag = get(slRoiPatch,'Tag');
            roiPatchArray = self.getRoiPatchArray();
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                tag = get(roiPatch,'Tag');
                if strcmp(tag,slTag)
                    roiPatch.Selected = 'on';
                else
                    roiPatch.Selected = 'off';
                end
            end
        end
        
        function unselectAllRoiPatch(self)
            roiPatchArray = self.getRoiPatchArray();
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                roiPatch.Selected = 'off';
            end
        end
        
        function deleteRoiPatch(self,roiPatch)
            if roiPatch == self.currentRoiPatch
                self.currentRoiPatch = [];
            end
            delete(roiPatch)
        end
                
        function roiPatchArray = getRoiPatchArray(self)
            mapAxes = self.guiHandles.mapAxes;
            children = mapAxes.Children;
            patchInd = arrayfun(@isaRoiPatch,children);
            roiPatchArray = children(patchInd);
        end
        
        
        function holdTraceAxes(self,holdState)
            hold(self.guiHandles.traceAxes,holdState)
        end
        
        function plotTimeTrace(self,trace,roiId)
            traceFig = self.guiHandles.traceFig;                
            traceFig.Visible = 'on';
            figure(traceFig)
            if ~isempty(trace)
                if strcmp(self.controller.timeTraceState,'raw')
                    plot(trace{1},'Tag',sprintf('trace_%04d',roiId));
                elseif strcmp(self.controller.timeTraceState,'dfOverF')
                    plot(trace{2},'Tag',sprintf('trace_%04d',roiId));
                else
                    error('Wrong timeTraceState in Controller!')
                end
            else
                cla(traceFig.CurrentAaxes)
            end
            figure(self.guiHandles.mainFig)
        end
        
        function deleteTraceLine(self,roiId)
            traceAxes = self.guiHandles.traceAxes;
            tag = sprintf('trace_%04d',roiId);
            lineInd = find(arrayfun(@(x) strcmp(x.Tag,tag), ...
                                    traceAxes.Children));
            if lineInd
                delete(traceAxes.Children(lineInd));
            end
        end

    end
    
    
    methods (Static)
        function updateMapDisplay(self,src,event)
            preContrastLim = self.getCurrentContrastLim();
            switch src.Name
              case 'anatomyMap'
                if strcmp(self.currentMapName,'anatomy')
                    self.plotMap('response');
                end
              case 'responseMap'
                if strcmp(self.currentMapName,'response')
                    self.plotMap('response');
                end
            end
            minCData = self.guiHandles.contrastMinSlider.Min;
            maxCData = self.guiHandles.contrastMinSlider.Max;
            postContrastLim = [max(preContrastLim(1),minCData), ...
                               min(preContrastLim(2),maxCData)];
            self.setCurrentContrastLim(postContrastLim);
        end
        
        
        
        % function updateCurrentRoiDisplay(self,src,event)
        % % TODO current roi display after adding new            
        %     eventObj = event.AffectedObject;
        %     currentRoi = eventObj.currentRoi;
            
        %     if ~isempty(currentRoi)
        %         roiPatchArray = self.getRoiPatchArray();
        %         for i=1:length(roiPatchArray)
        %             roiPatch = roiPatchArray(i);
        %             roiHandle = getappdata(roiPatch,'roiHandle');
        %             if roiHandle == currentRoi
        %                 self.currentRoiPatch = roiPatch;
        %                 set(roiPatch,'Facecolor','red')
        %             else
        %                 set(roiPatch,'Facecolor',self.unselectedRoiColor)
        %             end
        %         end
        %     else
        %         if ~isempty(self.currentRoiPatch)
        %             set(self.currentRoiPatch,'Facecolor',self.unselectedRoiColor)
        %         end
        %     end
        % end

        function toggleRoiDisplay(self,src,event)
            affectedObj = event.AffectedObject;
            roiDisplayState = affectedObj.roiDisplayState;
            if roiDisplayState
                visibility = 'on';
            else
                visibility = 'off';
            end
            
            roiPatchArray = self.getRoiPatchArray();
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                set(roiPatch,'Visible',visibility);
            end
        end
        
        function updateContrastSliders(self,src,event)
            himage = event.AffectedObject;
            cdata = get(himage,'CData');
            cdlim = minMax(cdata);
            set(self.guiHandles.contrastMinSlider,'Min',cdlim(1), ...
                              'Max',cdlim(2),'Value',cdlim(1));
            set(self.guiHandles.contrastMaxSlider,'Min',cdlim(1), ...
                              'Max',cdlim(2),'Value',cdlim(2));
        end
        
        function adjustContrast(self,src,event)
            contrastLim = self.getCurrentContrastLim();
            if contrastLim(1) < contrastLim(2)
                caxis(self.guiHandles.mapAxes,contrastLim);
            end
        end
        
    end
end    
