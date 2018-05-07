classdef NrView < handle
    properties
        gui
        model
        controller
        
        guiHandles
    end
    
    methods
        function self = NrView(controller)
            self.controller = controller;
            self.model = controller.model;
            self.gui = neuRoiGui('controller',self.controller);
            self.guiHandles = guidata(self.gui);
            self.guiHandles.mapImage =  imagesc(self.model.anatomyMap,'Parent', ...
                                        self.guiHandles.mapAxes);
            addlistener(self.model,'displayState','PostSet',...
                        @(src,event)NrView.changeDisplay(self,src, ...
                                                         event));

            self.assignCallback();
        end
        
        function assignCallback(self)
            set(self.guiHandles.anatomyButton,'Callback',...
               @(src,event)self.anatomy_Callback());
            set(self.guiHandles.responseButton,'Callback',...
               @(src,event)self.response_Callback());
            set(self.guiHandles.addRoiButton,'Callback',...
               @(src,event)self.addRoi_Callback(src,event));
            % set(self.gui,'CloseRequestFcn',@(src,event)...
            %              self.controller.closeGUI(src,event));
            set(self.gui,'WindowKeyPressFcn',@(src,event)...
                         self.keyPressCallback(src,event));

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
        
        function keyPressCallback(self,src,event)
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
    end
end    
        

