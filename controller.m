classdef controller < handle
    properties
        model
        view
    end
    
    methods
        function self = controller(mymodel)
            self.model = mymodel;
            self.view = view(self);
        end
        
        function setDisplayState(self,displayState)
            if ismember(displayState, self.model.stateArray)
                self.model.displayState = displayState;
            else
                error('The state should be in array of states')
            end
        end
    end
end
