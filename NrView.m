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
                                        self.guiHandles.axes1);
            addlistener(self.model,'displayState','PostSet',...
                        @(src,event)NrView.changeDisplay(self,src,event));
            
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
    
    
    
    
    
    
    
    
    
    
    
    
    
