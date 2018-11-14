classdef NrModel < handle
    properties (SetObservable)
        trialArray
        currentTrialInd

        %loadMovieOption
        %preprocessOption
        %intensityOffset
        % offsetYxMat
        
    end
    
    methods
        function self = NrModel()
            self.trialArray = TrialModel.empty;
        end
        
        function trial = loadTrial(self,varargin)
            tagArray = arrayfun(@(x) x.tag,self.trialArray, ...
                                'Uniformoutput',false);
            tag = helper.generateRandomTag(6);
            nstep = 1;
            while ismember(tag,tagArray) && nstep < 100
                tag = helper.generateRandomTag(5);
                nstep = nstep+1;
            end
            
            trial = TrialModel(varargin{:});
            trial.tag = tag;
            self.trialArray(end+1) = trial;
        end
        
        function deleteTrial(self,tag)
            self.trialArray(ind) = [];
        end
        
        function trial = getTrial(self,tag)
            trial = self.trialArray(ind);
        end
        
        function ind = getTrialInd(self,tag)
        %a
        end
           
        function calcAndAddMapWrap(self,tagArray,varargin)
        %a
        end
        
        function updateMapWrap(self,tagArray,varargin)
        %a
        end
        
        function importMapWrap(self,tagArray,varargin)
        %a
        end
    end
end
