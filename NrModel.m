classdef NrModel < handle
    properties
        filePathArray
        trialArray
    end
    
    methods
        function self = NrModel(filePathArray)
            self.filePathArray = filePathArray;
            self.trialArray = cellfun(@NrTrial,filePathArray);
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray(ind);
        end
    end
    
end
