classdef NrModel < handle
    properties (SetObservable)
        filePathArray
        trialArray
        
        loadMovieOption
        preprocessOption
        currentTrialInd
    end
    
    methods
        function self = NrModel(filePathArray)
            self.filePathArray = filePathArray;
            nFile = length(filePathArray);
            self.trialArray = cell(1,nFile);
            
            self.loadMovieOption = ...
                TrialModel.calcDefaultLoadMovieOption();
        end
        
        function nFile = getNFile(self)
            nFile = length(self.filePathArray);
        end
            
        function addFilePath(self,filePath)
            self.filePathArray{end+1} = filePath;
        end
        
        function loadTrial(self,ind)
            filePath = self.filePathArray{ind};
            self.trialArray{ind} = TrialModel(filePath, ...
                                              self.loadMovieOption);
            % 2018-08-15 BO Hu
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray{ind};
        end
    end
    
end
