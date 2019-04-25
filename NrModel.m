classdef NrModel < handle
    properties (SetObservable)
        rawDataDir
        rawFileList
        resultDir
        
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
    
    properties (SetAccess = private, SetObservable = true)
        binConfig
        anatomyConfig
        alignConfig
    end
    
    methods
        function self = NrModel(rawDataDir,rawFileList,resultDir, ...
                                expInfo,varargin)
            self.trialArray = TrialModel.empty;
            
            self.rawDataDir = rawDataDir;
            self.rawFileList = rawFileList;
            self.resultDir = resultDir;
            
            % self.binConfig.outDir = fullfile(resultDir,'binned_movie');
            self.anatomyConfig.outDir = fullfile(resultDir,'anatomy');
            self.alignConfig.outDir = fullfile(resultDir,'alignment');
            
            % if isfield(expParam,'alignFilePath')
            %     foo = load(expParam.alignFilePath);
            %     self.regResult = foo.regResult;
            % end
            % self.responseOption = expConfig.responseOption;
            % self.responseMaxOption = expConfig.responseMaxOption;
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
                filePath = fullfile(self.rawDataDir, ...
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

        function binMovieBatch(self,param,outDir,fileIdx)
            if ~exist('outDir','var')
                if length(self.binConfig.outDir)
                    outDir = self.binConfig.outDir;
                else
                    error('Please specify output directory!')
                end
            end
            if ~exist(outDir,'dir')
                mkdir(outDir)
            end
            
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList(fileIdx);
            end
            % TODO change trialOption for multiplane analysis
            binConfig = batch.binMovieFromFile(self.rawDataDir, ...
                                                rawFileList, ...
                                                outDir,...
                                                param.shrinkFactors,...
                                                param.depth,...
                                                param.trialOption);
            self.binConfig = binConfig;
        end
        
        function readBinConfig(self,metaFilePath)
            self.binConfig = jsondecode(fileread(metaFilePath));
        end
        
        function calcAnatomyBatch(self,param,fileIdx)
            outDir = self.anatomyConfig.outDir;
            if ~exist(outDir,'dir')
                mkdir(outDir)
            end

            if ~isfield(param,'trialOption')
                param.trialOption = {};
            end
            
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList(fileIdx);
            end
            
            if strcmp(param.inFileType,'raw')
                filePrefix = batch.calcAnatomyFromFile(self.rawDataDir, ...
                                                       rawFileList,...
                                                       outDir, ...
                                                       param.trialOption);
            elseif strcmp(param.inFileType,'binned')
                binDir = self.binConfig.outDir;
                if self.binConfig.filePrefix
                    binPrefix = self.binConfig.filePrefix;
                    binnedFileList = ...
                        iopath.modifyFileName(rawFileList,binPrefix,'','tif');
                end
                try
                    [~,filePrefix] = batch.calcAnatomyFromFile(binDir, ...
                                 binnedFileList,outDir,param.trialOption);
                catch ME
                    if strcmp(ME.identifier, ...
                              'batchCalcAnatomyFromFile:fileNotFound')
                        addMsg = ['Binned data does not exist! Please do ' ...
                               'binning first before calculating anatomy.'];
                        disp(addMsg)
                    end
                    rethrow(ME)
                end
                filePrefix = [filePrefix,binPrefix];
            end
            self.anatomyConfig.outDir = outDir;
            self.anatomyConfig.param = param;
            self.anatomyConfig.filePrefix = filePrefix;
        end
    end
end
