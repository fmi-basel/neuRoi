classdef NrModel < handle
    properties (SetObservable)
        filePathArray
        trialArray
        
        loadMovieOption
        noSignalWindow
        currentTrialInd
    end
    
    methods
        function self = NrModel(filePathArray)
            self.filePathArray = filePathArray;
            nFile = length(filePathArray);
            self.trialArray = cell(1,nFile);
            
            self.loadMovieOption = ...
                TrialModel.calcDefaultLoadMovieOption();
            self.noSignalWindow = [1 12];
        end
        
        function nFile = getNFile(self)
            nFile = length(self.filePathArray);
        end
            
        function addFilePath(self,filePath)
            self.filePathArray{end+1} = filePath;
        end
        
        function loadTrial(self,ind)
            filePath = self.filePathArray{ind};
            trial = TrialModel(filePath, ...
                               self.loadMovieOption);
            trial.preprocessMovie(self.noSignalWindow);
            self.trialArray{ind} = trial;
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray{ind};
        end
    end
    
end
