classdef NrModel < handle
    properties (SetObservable)
        expConfig
        rawFileList
        regResult
        binParam
        responseOption
        responseMaxOption
        
        trialArray
        currentTrialIdx
        
        mapsAfterLoading
        roiTemplateFilePath
        doLoadTemplateRoi
        processOption
        % TODO big TODO change intensityOffset specification
        intensityOffset
        
        loadFileType
    end
    
    methods
        function self = NrModel(expConfig)
        % TODO unpack expConfig
            self.trialArray = TrialModel.empty;
            self.expConfig = expConfig;
            self.rawFileList = expConfig.rawFileList;
            
            if isfield(expConfig,'alignFilePath')
                foo = load(expConfig.alignFilePath);
                self.regResult = foo.regResult;
            end
            self.binParam = expConfig.binParam;
            self.responseOption = expConfig.responseOption;
            self.responseMaxOption = expConfig.responseMaxOption;
            self.mapsAfterLoading = {};
            self.loadFileType = 'raw';
            
            % TODO big TODO optimize processOption specification
            self.processOption.process = true;
            self.processOption.noSignalWindow = [1 12];

        end

        function tagArray = getTagArray(self)
            tagArray = arrayfun(@(x) x.tag,self.trialArray, ...
                                'Uniformoutput',false);
        end
        
        function idx = getTrialIdx(self,tag)
            tagArray = self.getTagArray();
            idx = find(strcmp(tagArray,tag));
        end
        
        function trial = getTrialByTag(self,tag)
            idx = self.getTrialIdx(tag);
            trial = self.trialArray(idx);
        end

        function trial = loadTrialFromList(self,fileIdx,fileType,varargin)
            rawFileName = self.rawFileList{fileIdx};
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
            
            % TODO make other trial options explicit
            trial = self.loadTrial(filePath,'process', ...
                                 self.processOption.process,...
                                 'noSignalWindow',...
                                 self.processOption.noSignalWindow,...
                             'intensityOffset',self.intensityOffset,...
                                 'yxShift',offsetYx,...
                                 'resultDir',self.expConfig.roiDir,...
                                 'frameRate',frameRate);
            trial.sourceFileIdx = fileIdx;
        end
        
        function trial = loadAdditionalTrial(self,filePath,varargin)
        % TODO save trial path into a property
            trial = self.loadTrial(filePath,varargin{:});
        end
        
        function trial = loadTrial(self,filePath,varargin)
            tagArray = self.getTagArray();
            tag = helper.generateRandomTag(6);
            nstep = 1;
            while ismember(tag,tagArray) && nstep < 100
                tag = helper.generateRandomTag(5);
                nstep = nstep+1;
            end
            
            trial = TrialModel(filePath,varargin{:});
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
