classdef view < handle
    properties
        gui
        model
        controller
    end
    
    methods
        function self = view(controller)
            self.controller = controller;
            self.model = controller.model;
            self.gui = neuRoiGui('controller',self.controller);
            handles = guidata(self.gui);
            imagesc(self.model.anatomyMap,'Parent', handles.axes1);
            addlistener(self.model,'displayState','PostSet',...
                        @(src,event)view.changeDisplay(self,src,event));
            
        end
    end

    methods (Static)
        function changeDisplay(self,src,event)
            eventObj = event.AffectedObject;
            handles = guidata(self.gui);
            switch eventObj.displayState
              case 'anatomy'
                imagesc(self.model.anatomyMap,'Parent',handles.axes1);
              case 'response'
                imagesc(self.model.responseMap,'Parent',handles.axes1);
            end
        end
        %%%%% or add a listener to displayState???
        
            
        % function handlePropEvents(self,src,evnt)
        %     evntobj = evnt.AffectedObject;
        %     handles = guidata(self.gui);
        %     switch src.Name
        %       case 'anatomy'
        %         set(handles.axes1,'CData',self.model.anatomyMap)
        %       case 'response'
        %         set(handles.axes1,'CData',self.model.responseMap)
        %     end
        % end
    end
end    
    
    
    
    
    
    
    
    
    
    
    
    
    
