classdef NrModel < handle
    properties (SetObservable)
        filePathArray
        trialArray
    end
    
    methods
        function self = NrModel(filePathArray)
            self.filePathArray = filePathArray;
            self.trialArray = cellfun(@NrTrialModel,filePathArray);
        end
        
        function addFilePath(self,filePath)
            self.filePathArray{end+1} = filePath;
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray(ind);
        end
    end
    
end
