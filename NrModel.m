classdef NrModel < handle
    properties (SetObservable)
        filePathArray
        trialArray
        loadMovieOption
    end
    
    methods
        function self = NrModel(filePathArray)
            self.filePathArray = filePathArray;
            nFile = length(filePathArray);
            self.trialArray = cell(1,nFile);
        end
        
        function addFilePath(self,filePath)
            self.filePathArray{end+1} = filePath;
        end
        
        function loadTrial(self,ind)
            filePath = self.filePathArray{ind};
            self.trialArray{ind} = TrialModel(filePath,self.loadMovieOption);
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray{ind};
        end
    end
    
end
