classdef NrModel < handle
    properties (SetObservable)
        expConfig
        regResult
        binParam
        responseOption
        responseMaxOption
        trialArray
        currentTrialIdx
    end
    
    methods
        function self = NrModel(expConfig)
        % TODO unpack expConfig
            self.expConfig = expConfig;
            self.trialArray = TrialModel.empty;
            
            if isfield(expConfig,'alignFilePath')
                foo = load(expConfig.alignFilePath);
                self.regResult = foo.regResult;
            end
            self.binParam = expConfig.binParam;
            self.responseOption = expConfig.responseOption;
            self.responseMaxOption = expConfig.responseMaxOption;
        end

        function tagArray = getTagArray(self)
            tagArray = arrayfun(@(x) x.tag,self.trialArray, ...
                                'Uniformoutput',false);
        end
        
        function idx = getTrialIdx(self,tag)
            tagArray = self.getTagArray();
            idx = find(strcmp(tagArray,tag));
        end
        
        function trial = loadTrial(self,fileIdx,fileType,varargin)
            rawFileName = self.expConfig.rawFileList{fileIdx};
            switch fileType
              case 'raw'
                fileName = rawFileName;
                filePath = fullfile(self.expConfig.rawDataDir, ...
                                    fileName);
                frameRate = self.expConfig.frameRate;
              case 'binned'
                shrinkFactors = self.binParam.shrinkFactors;
                fileName = iopath.getBinnedFileName(rawFileName, ...
                                                    shrinkFactors);
                filePath = fullfile(self.expConfig.binnedDir, ...
                                    fileName);
                frameRate = self.expConfig.frameRate / shrinkFactors(3);
            end
            

            if isstruct(self.regResult)
                offsetYx = self.regResult.offsetYxMat(fileIdx,:);
            else
                offstYx = [0,0];
            end
            
            tagArray = self.getTagArray();
            tag = helper.generateRandomTag(6);
            nstep = 1;
            while ismember(tag,tagArray) && nstep < 100
                tag = helper.generateRandomTag(5);
                nstep = nstep+1;
            end
            
            % TODO make other trial options explicit
            trial = TrialModel(filePath,varargin{:},'yxShift',offsetYx,...
                               'frameRate',frameRate);
            trial.tag = tag;
            self.trialArray(end+1) = trial;
            
            % self.filetagList(fileIdx)
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
        
        function mapOption = getMapOption(self,mapType)
            switch mapType
              case 'response'
                mapOption = self.responseOption;
              case 'responseMax'
                mapOption = self.responseMaxOption;
              otherwise
                error('NrModel:mapTypeTagError',['Map type of ' ...
                                    'the button is wrong!'])
            end
        end
        
        function addMapCurrTrial(self,mapType)
            mapOption = self.getMapOption(mapType);
            trial = self.getCurrentTrial();
            
            try
                trial.calculateAndAddNewMap(mapType,mapOption);
            catch ME
                if strcmp(ME.identifier,['TrialModel:' ...
                                        'windowValueError'])
                    self.view.displayError(ME);
                    return
                end
                rethrow(ME)
            end
        end
        
        function updateMapCurrTrial(self,mapType)
            mapOption = self.getMapOption(mapType);
            trial = self.getCurrentTrial();
            try
                trial.findAndUpdateMap(mapType,mapOption);
            catch ME
                switch ME.identifier
                  case 'TrialModel:mapTypeError','TrialModel:windowValueError'
                    self.view.displayError(ME);
                    return
                end
                rethrow(ME)
            end
                
        end
        
        % function updateMapWrap(self,tagArray,varargin)
        %     if strcmp(tagArray,'current')
        %         trial = self.trialArray(self.currentTrialIdx);
        %         trial.findAndUpdateMap(varargin{:});
        %     end
        % end
    end
end
