classdef NrModel < handle
    properties (SetObservable)
        trialArray
        currentTrialIdx
    end
    
    methods
        function self = NrModel()
            self.trialArray = TrialModel.empty;
        end

        function tagArray = getTagArray(self)
            tagArray = arrayfun(@(x) x.tag,self.trialArray, ...
                                'Uniformoutput',false);
        end
        
        function idx = getTrialIdx(self,tag)
            tagArray = self.getTagArray();
            idx = find(strcmp(tagArray,tag));
        end
        
        function trial = loadTrial(self,varargin)
            tagArray = self.getTagArray();
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
        
        function selectTrial(self,tag)
            if isempty(tag)
                self.currentTrialIdx = [];
                disp('No trial is selected..')
            else
                idx = self.getTrialIdx(tag);
                if isempty(idx)
                    disp('No trial is selected')
                else
                    if ~isequal(idx,self.currentTrialIdx)
                        self.currentTrialIdx = idx;
                        disp(sprintf('trial_%s # %d selected', tag, ...
                                     self.currentTrialIdx))
                    end
                end
            end
        end
        
        function deleteTrial(self,idx)
            self.trialArray(idx) = [];
        end
        
        function trial = getCurrentTrial(self)
            trial = self.trialArray(self.currentTrialIdx);
        end
           
        function addMapWrap(self,tagArray,varargin)
            if strcmp(tagArray,'current')
                trial = self.trialArray(self.currentTrialIdx);
                trial.calculateAndAddNewMap(varargin{:});
            end
        end
        
        function updateMapWrap(self,tagArray,varargin)
            if strcmp(tagArray,'current')
                trial = self.trialArray(self.currentTrialIdx);
                trial.findAndUpdateMap(varargin{:});
            end
        end
        
        function importMapWrap(self,tagArray,varargin)
            if strcmp(tagArray,'current')
                trial = self.trialArray(self.currentTrialIdx);
                trial.importMap(varargin{:});
            end
        end
    end
end
