classdef NrView < handle
    properties
        model
        controller
        
        guiHandles
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
           
            self.guiHandles.mapImage =  imagesc(self.model.anatomyMap,'Parent', ...
                                        self.guiHandles.mapAxes);
            
            self.assignCallbacks();
            self.addListners();
        end
        
        function addListners(self)
            addlistener(self.model,'displayState','PostSet', ...
                        @(src,event)NrView.changeDisplay(self,src,event));
            
            addlistener(self.model,'currentRoi','PostSet', ...
                        @(src,event)NrView.changeCurrentRoiDisplay(self,src,event));
            
            addlistener(self.model,'currentTimeTrace','PostSet', ...
                        @(src,event)NrView.plotTimeTrace(self,src,event));
            

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
        end
                
    end

    % Callback functions
    methods
        function anatomy_Callback(self)
            self.controller.setDisplayState( 'anatomy');
        end
        
        function response_Callback(self)
            self.controller.setDisplayState( 'response');
        end
        
        function addRoi_Callback(self,src,event)
            self.controller.addRoi();
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
    end

    % Methods for viewing ROIs
    methods
        function addRoiPatch(self,roi)
            createRoiPatch(roi,self.guiHandles.mapAxes);
        end
        
        function deleteRoiPatch(self,roiPatch)
            if roiPatch == self.currentRoiPatch
                self.currentRoiPatch = [];
            end
            delete(roiPatch)
        end
        
        function addRoiPatchArray(self,roiArray)
            cellfun(@(x) self.addRoiPatch(x),roiArray);
        end
        
        function roiPatchArray = getRoiPatchArray(self)
            mapAxes = self.guiHandles.mapAxes;
            children = mapAxes.Children;
            patchInd = arrayfun(@isaRoiPatch,children);
            roiPatchArray = children(patchInd);
        end
    end
    
    
    methods (Static)
        function changeDisplay(self,src,event)
            eventObj = event.AffectedObject;
            hMapImage = self.guiHandles.mapImage;
            switch eventObj.displayState
              case 'anatomy'
                set(hMapImage,'CData',eventObj.anatomyMap)
              case 'response'
                set(hMapImage,'CData',eventObj.responseMap)
              case 'masterResponse'
                set(hMapImage,'CData',eventObj.masterResponseMap)
              case 'localCorr'
                set(hMapImage,'CData',eventObj.localCorrMap)
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
    end
end    
