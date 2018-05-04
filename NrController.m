classdef NrController < handle
    properties
        model
        view
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(self);
        end
        
        function setDisplayState(self,displayState)
            if ismember(displayState, self.model.stateArray)
                if strcmp(displayState,'localCorr') & ~self.model.localCorrMap
                        self.model.calcLocalCorrelation();
                end
                self.model.displayState = displayState;
            else
                error('The state should be in array of states')
            end
        end
        
        function addRoi(self)
            roi = ExtFreehandRoi();
            self.model.addRoi(roi);
        end
        
    end
end
