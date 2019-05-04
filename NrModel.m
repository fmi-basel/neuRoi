classdef NrModel < handle
    properties (SetObservable)
        expInfo
        
        rawDataDir
        rawFileList
        resultDir

        trialArray
        currentTrialIdx
        
        alignFilePath
        alignResult

        responseOption
        responseMaxOption
        
        roiDir
        
        loadFileType
        trialOptionRaw
        trialOptionBinned
        alignToTemplate
        mapsAfterLoading
        loadTemplateRoi
        roiTemplateFilePath        
    end 
    
    properties (SetAccess = private, SetObservable = true)
        binConfig
        anatomyConfig
        alignConfig
    end
    
    methods
        function self = NrModel(rawDataDir,rawFileList,resultDir, ...
                                expInfo,varargin)
            pa = inputParser;
            addRequired(pa,'rawDataDir');
            addRequired(pa,'rawFileList');
            addRequired(pa,'resultDir');
            addRequired(pa,'expInfo');
            addParameter(pa,'alignFilePath','',@ischar)
            addParameter(pa,'roiDir','',@ischar);
            addParameter(pa,'loadFileType','raw',@ischar);
            defaultTrialOptionRaw = struct('process',true,...
                                'noSignalWindow',[1 12], ...
                                'intensityOffset',-30);
            defaultTrialOptionBinned = struct('process',false,...
                                'noSignalWindow',[], ...
                                'intensityOffset',100);
            addParameter(pa,'trialOptionRaw',defaultTrialOptionRaw, ...
                         @isstruct);
            addParameter(pa,'trialOptionBinned', ...
                         defaultTrialOptionBinned,@isstruct);
            
            
            defaultResponseOption = struct('offset',0,...
                                           'fZeroWindow',[1 5],...
                                           'responseWindow',[10 15]);
            defaultResponseMaxOption = struct('offset',0,...
                                              'fZeroWindow',[1 5],...
                                              'slidingWindowSize',3);

            addParameter(pa,'responseOption',defaultResponseOption, ...
                         @isstruct);
            addParameter(pa,'responseMaxOption', ...
                         defaultResponseMaxOption,@isstruct);
            

            parse(pa,rawDataDir,rawFileList,resultDir,expInfo, ...
                  varargin{:})
            pr = pa.Results;

            self.trialArray = TrialModel.empty;
            
            self.expInfo = expInfo;
            self.rawDataDir = rawDataDir;
            self.rawFileList = rawFileList;
            self.resultDir = resultDir;
            
            self.anatomyConfig.outDir = self.getDefaultDir('anatomy');
            
            if ~isempty(pr.alignFilePath)
                self.loadAlignResult(pr.alignFilePath);
                self.alignToTemplate = true;
            else
                self.alignConfig.outDir = ...
                    self.getDefaultDir('alignment');
                self.alignToTemplate = false;
            end
            
            if ~isempty(pr.roiDir)
                self.roiDir = pr.roiDir;
            else
                self.roiDir = self.getDefaultDir('roi');
            end
            
            self.loadFileType = pr.loadFileType;
            self.trialOptionRaw = pr.trialOptionRaw;
            self.trialOptionBinned = pr.trialOptionBinned;
            self.responseOption = pr.responseOption;
            self.responseMaxOption = pr.responseMaxOption;
            self.mapsAfterLoading = {};
            self.loadTemplateRoi = false;
            self.roiTemplateFilePath = '';
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

        function trial = loadTrialFromList(self,fileIdx,fileType)
            rawFileName = self.rawFileList{fileIdx};
            switch fileType
              case 'raw'
                fileName = rawFileName;
                filePath = fullfile(self.rawDataDir, ...
                                    fileName);
                frameRate = self.expConfig.frameRate;
                trialOption = self.trialOptionRaw;
              case 'binned'
                shrinkFactors = self.binConfig.param.shrinkFactors;
                fileName = iopath.getBinnedFileName(rawFileName, ...
                                                    shrinkFactors);
                filePath = fullfile(self.binConfig.outDir, ...
                                    fileName);
                frameRate = self.expInfo.frameRate / ...
                    shrinkFactors(3);
                trialOption = self.trialOptionBinned;
            end
            

            % TODO change align option to loadTrialOption
            if self.alignToTemplate
                if isempty(self.alignResult)
                    error('No alignment result loaded!')
                end
                inFileList = self.alignResult.inFileList;
                anatomyPrefix = self.alignResult.anatomyPrefix;
                anatomyFileName = ...
                    iopath.modifyFileName(rawFileName, ...
                                          anatomyPrefix,'','tif');
                idx = find(strcmp(inFileList,anatomyFileName));
                if isempty(idx)
                    msg = ['Cannot find offset value in the aligment ' ...
                           'result for file: ' anatomyFileName];
                    error(msg);
                else
                    offsetYx = self.alignResult.offsetYxMat(idx,:);
                end
            else
                warning('The trials might not be aligned in X and Y!')
                offstYx = [0,0];
            end
            
            trialOption.yxShift = offsetYx;
            trialOption.resultDir = self.roiDir;
            trialOption.frameRate = frameRate;
            trialOptionCell = helper.structToNameValPair(trialOption);
            trial = self.loadTrial(filePath,trialOptionCell);
            trial.sourceFileIdx = fileIdx;
        end
        
        function trial = loadAdditionalTrial(self,filePath,varargin)
        % TODO save trial path into a property
            trial = self.loadTrial(filePath,varargin{:});
        end
        
        function trial = loadTrial(self,filePath,trialOption)
            tagArray = self.getTagArray();
            tag = helper.generateRandomTag(6);
            nstep = 1;
            while ismember(tag,tagArray) && nstep < 100
                tag = helper.generateRandomTag(5);
                nstep = nstep+1;
            end
            
            trial = TrialModel(filePath,trialOption{:});
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

        function binMovieBatch(self,param,outDir,planeNum,fileIdx)
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
            
            trialOption = param.trialOption;
            if self.expInfo.nPlane > 1
                if exist('planeNum','var')
                    planeSubDir = NrModel.getPlaneSubDir(planeNum);
                    outDir = fullfile(outDir,planeSubDir);
                    if ~exist(outDir,'dir')
                        mkdir(outDir)
                    end
                    trialOption.nFramePerStep = self.expInfo.nPlane;
                    trialOption.zrange = [planeNum,inf];
                else
                    error(['Please specify plane number for' ...
                           ' multiplane data!']);
                end
            end

            
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList;
            end
            % TODO change trialOption for multiplane analysis
            binConfig = batch.binMovieFromFile(self.rawDataDir, ...
                                               rawFileList, ...
                                               outDir,...
                                               param.shrinkFactors,...
                                               param.depth,...
                                               trialOption);
            
            self.binConfig = binConfig;
            timeStamp = helper.getTimeStamp();
            configFileName = ['binConfig-' timeStamp '.json'];
            configFilePath = fullfile(outDir,configFileName);
            helper.saveStructAsJson(binConfig,configFilePath);
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
                rawFileList = self.rawFileList;
            end
            
            if strcmp(param.inFileType,'raw')
                [~,filePrefix] = batch.calcAnatomyFromFile(self.rawDataDir, ...
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
            
            anatomyConfig.outDir = outDir;
            anatomyConfig.param = param;
            anatomyConfig.filePrefix = filePrefix;
            
            self.anatomyConfig = anatomyConfig;

            configFileName = ['anatomyConfig.json'];
            configFilePath = fullfile(outDir,configFileName);
            helper.saveStructAsJson(anatomyConfig,configFilePath);
        end
        
        function readAnatomyConfig(self,filePath)
            self.anatomyConfig = jsondecode(fileread(filePath));
        end

        function alignTrialBatch(self,templateRawName,outFileName, ...
                                 varargin)
            outDir = self.alignConfig.outDir;
            if ~exist(outDir,'dir')
                mkdir(outDir)
            end

            anatomyPrefix = self.anatomyConfig.filePrefix;
            templateName = iopath.modifyFileName(templateRawName, ...
                                           anatomyPrefix,'','tif');
            
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList;
            end

            % TODO deal with error that no anatomy files found
            % TODO deal with no anatomyConfig loaded
            
            anatomyFileList = iopath.modifyFileName(rawFileList, ...
                                                    anatomyPrefix, ...
                                                    '','tif');
            stackFileName = iopath.modifyFileName(outFileName, ...
                                                  'stack_','','tif');
            stackFilePath = fullfile(outDir,stackFileName);
            alignResult = batch.alignTrials(self.anatomyConfig.outDir,...
                                            anatomyFileList, ...
                                            templateName,...
                                            'stackFilePath',...
                                            stackFilePath,...
                                            varargin{:});
            
            alignResult.anatomyPrefix = anatomyPrefix;
            alignResult.templateRawName = templateRawName;

            self.alignResult = alignResult;
            self.alignConfig.outFileName = outFileName;
            outFilePath = fullfile(outDir,outFileName);
            save(outFilePath,'alignResult')
            
            % TODOTODO save aligned image stack
        end

        function loadAlignResult(self,filePath)
            try
                foo = load(filePath);
            catch ME
                disp('Could not load alignment result!')
                disp(['File path:' filePath])
                rethrow ME
            end
            self.alignResult = foo.alignResult;
            [outDir,outFileName,~] = fileparts(filePath);
            self.alignConfig.outDir = outDir;
            self.alignConfig.outFileName = outFileName;
        end

        function dd = getDefaultDir(self,dirName)
            switch dirName
              case 'binned'
                dd = fullfile(self.resultDir,'binned');
              case 'anatomy'
                dd = fullfile(self.resultDir,'anatomy');
              case 'alignment'
                dd = fullfile(self.resultDir,'alignment');
              case 'response_map'
                dd = fullfile(self.resultDir,'response_map');
              case 'roi'
                dd = fullfile(self.resultDir,'roi');
            end
        end
        
        function fileList = getFileList(self,resultType,fileIdx)
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList;
            end
            
            switch resultType
              case 'binned'
                    binPrefix = self.binConfig.filePrefix;
                    fileList = iopath.modifyFileName(rawFileList, ...
                                                     binPrefix,'','tif');
            end
        end
        
        function s = saveobj(self)
            for fn = fieldnames(self)'
                s.(fn{1}) = self.(fn{1});
            end
        end
    end

    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                obj = NrModel(s.rawDataDir,s.rawFileList, ...
                              s.resultDir,s.expInfo);
                
                for fn = fieldnames(s)'
                    if ~ismember(fn,{'rawDataDir','rawFileList', ...
                                     'resultDir','expInfo'})
                        obj.(fn{1}) = s.(fn{1});
                    end
                end
                
                if isstruct(obj.alignResult)
                    obj.alignToTemplate = true;
                end
            else
                obj = s;
            end
        end
    
        function planeSubDir = getPlaneSubDir(planeNum)
            planeSubDir = sprintf('plane%02d',planeNum)
        end
    end
    
end
