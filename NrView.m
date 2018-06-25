classdef NrView < handle
    properties
        model
        controller
        
        guiHandles
        displayState
        currentRoiPatch
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
            self.plotMap('anatomy');
            
            self.assignCallbacks();
            self.addListners();
        end
        
        function addListners(self)
            addlistener(self.model,'responseMap','PostSet', ...
                        @(src,event)NrView.changeMapDisplay(self,src,event));

            addlistener(self.model,'currentRoi','PostSet', ...
                        @(src,event)NrView.changeCurrentRoiDisplay(self,src,event));
            
            addlistener(self.model,'currentTimeTrace','PostSet', ...
                        @(src,event)NrView.plotTimeTrace(self,src, ...
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
                @(src,event)self.anatomy_Callback());
            set(self.guiHandles.responseButton,'Callback',...
                @(src,event)self.response_Callback());
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
        function anatomy_Callback(self)
            self.displayState = 'anatomy';
            self.plotMap('anatomy');
            % Update contrast slider
        end
        
        function response_Callback(self)
            self.displayState = 'response';
            self.plotMap('response');
            % Update contrast slider
        end
        
        function addRoi_Callback(self,src,event)
            self.controller.addRoiInteract();
        end
        
        function selectRoi_Callback(self,src,event)
            self.controller.selectRoi();
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
                self.anatomy_Callback()
              case 'w'
                self.response_Callback()
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
              case 'masterResponse'
                set(hMapImage,'CData',self.model.masterResponseMap)
              case 'localCorr'
                set(hMapImage,'CData',self.model.localCorrMap)
            end
        end

        
        % Methods for viewing ROIs
        function addRoiPatch(self,roi)
            createRoiPatch(roi,self.guiHandles.mapAxes);
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
    end
    
    
    methods (Static)
        function changeMapDisplay(self,src,event)
            switch src.Name
              case 'anatomyMap'
                if strcmp(self.displayState,'response')
                    self.plotMap('response');
                end
              case 'responseMap'
                if strcmp(self.displayState,'response')
                    self.plotMap('response');
                end
            end
        end
        
        function plotTimeTrace(self,src,event)
            eventObj = event.AffectedObject;
            currentTimeTrace = eventObj.currentTimeTrace;

            traceFig = self.guiHandles.traceFig;                
            traceFig.Visible = 'on';
            figure(traceFig)
            if ~isempty(currentTimeTrace)
                plot(currentTimeTrace)
            else
                cla(traceFig.CurrentAxes)
            end
            figure(self.guiHandles.mainFig)
        end
        
        function changeCurrentRoiDisplay(self,src,event)
        % TODO current roi display after adding new     
       
            display('currentRoi changed')
            eventObj = event.AffectedObject;
            currentRoi = eventObj.currentRoi;
            
            if ~isempty(currentRoi)
                roiPatchArray = self.getRoiPatchArray();
                for i=1:length(roiPatchArray)
                    roiPatch = roiPatchArray(i);
                    roiHandle = getappdata(roiPatch,'roiHandle');
                    if roiHandle == currentRoi
                        self.currentRoiPatch = roiPatch;
                        set(roiPatch,'Facecolor','red')
                    else
                        set(roiPatch,'Facecolor','yellow')
                    end
                end
            else
                if ~isempty(self.currentRoiPatch)
                    set(self.currentRoiPatch,'Facecolor','yellow')
                end
            end
        end
        
        function updateContrastSliders(self,src,event)
            himage = event.AffectedObject;
            cdata = get(himage,'CData');
            minCData = min(cdata(:));
            maxCData = max(cdata(:));
            set(self.guiHandles.contrastMinSlider,'Min',minCData, ...
                              'Max',maxCData,'Value',minCData);
            set(self.guiHandles.contrastMaxSlider,'Min',minCData,'Max',maxCData,'Value',maxCData);
        end
        
        function adjustContrast(self,src,event)
            minSliderVal = get(self.guiHandles.contrastMinSlider, ...
                               'Value');
            maxSliderVal = get(self.guiHandles.contrastMaxSlider, ...
                               'Value');
            caxis(self.guiHandles.mapAxes,[minSliderVal,maxSliderVal]);
        end
        
    end
end    
