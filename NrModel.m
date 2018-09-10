classdef NrModel < handle
    properties (SetObservable)
        filePathArray
        trialArray

        offsetYxMat
        
        loadMovieOption
        noSignalWindow
        intensityOffset
        
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
            if self.offsetYxMat
                offsetYx = offsetYxMat(ind,:);
                trial.shiftMovieYx(offsetYx);
            end
            % trial.preprocessMovie(self.noSignalWindow);
            trial.intensityOffset = self.intensityOffset;
            self.trialArray{ind} = trial;
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray{ind};
        end
    end
    
end
