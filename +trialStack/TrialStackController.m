classdef TrialStackController < handle
    properties
        model
        view
    end
    
    methods
        function self = TrialStackController(mymodel)
            self.model = mymodel;
            self.view = trialStack.TrialStackView(self.model,self)
        end
        
        function keyPressCallback(self, src, evnt)
            if isempty(evnt.Modifier)
                switch evnt.Key
                  case {'rightarrow','leftarrow'}
                    self.slideTrialCallback(evnt)
                end
            end
        end
        
        function slideTrialCallback(self,evnt)
            if strcmp(evnt.Key, 'rightarrow')
                self.model.currentTrialIdx = self.model.currentTrialIdx+1;
            elseif strcmp(evnt.Key, 'leftarrow')
                self.model.currentTrialIdx = self.model.currentTrialIdx-1;
            end
        end
    end
    
end
