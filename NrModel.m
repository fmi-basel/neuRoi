classdef NrModel < handle
    properties (SetObservable)
        filePathArray
        trialArray

        offsetYxMat
        
        loadMovieOption
        preprocessOption
        intensityOffset
        
        resultDir
        
        currentTrialInd
    end
    
    methods
        function self = NrModel(filePathArray,varargin)
            self.filePathArray = filePathArray;
            nFile = length(filePathArray);
            self.trialArray = cell(1,nFile);
            
            if nargin == 1
                self.loadMovieOption = ...
                    TrialModel.calcDefaultLoadMovieOption();
                self.preprocessOption = struct('process',true,...
                                               'noSignalWindow',[1 ...
                                    12]);
            elseif nargin == 3
                self.loadMovieOption = varargin{1};
                self.preprocessOption = varargin{2};
            else
                error('Wrong usage!')
            end
                
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
                               self.loadMovieOption,...
                               self.preprocessOption);
            if ~isempty(self.offsetYxMat)
                offsetYx = self.offsetYxMat(ind,:);
                trial.shiftMovieYx(offsetYx);
            end
            trial.intensityOffset = self.intensityOffset;
            trial.resultDir = self.resultDir;
            self.trialArray{ind} = trial;
        end
        
        function trial = getTrialByInd(self,ind)
            trial = self.trialArray{ind};
        end
    end
    
end
