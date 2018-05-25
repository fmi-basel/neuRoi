classdef NrView < handle
    properties
        model
        controller
        
        guiHandles
    end
    
    methods
        function self = NrView(controller)
            self.controller = controller;
            self.model = controller.model;
            self.guiHandles = neuRoiGui();
            self.guiHandles.mainFig.Name = self.model.fileBaseName;
            self.guiHandles.traceFig.Name = [self.model.fileBaseName, ...
                   '_time_trace']
           
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
            set(self.guiHandles.mainFig,'WindowKeyPressFcn',@(src,event)...
                         self.keyPressCallback(src,event));
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
            end
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
            traceFig = self.guiHandles.traceFig;
            traceFig.Visible = 'on';
            figure(traceFig)
            plot(self.model.currentTimeTrace);
            figure(self.guiHandles.mainFig)
        end

        function changeCurrentRoiDisplay(self,src,event)
            display('currentRoi changed')
            eventObj = event.AffectedObject;
            currentRoi = eventObj.currentRoi;
            roiArray = eventObj.roiArray;
            if isvalid(currentRoi) && strcmp(class(currentRoi),'ExtFreehandRoi')
                for i=1:length(roiArray)
                    roi = roiArray{i};
                    if roi.id==currentRoi.id
                        setColor(roi,'red')
                    else
                        setColor(roi,'blue')
                    end
                end
            end
        end
    end
end    
        

