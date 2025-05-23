classdef NrModel < handle
    properties (SetObservable)
        expInfo
        
        rawDataDir
        rawFileList
        resultDir
        
        trialTable
        selectedFileIdx

        trialArray
        currentTrialIdx
        
        motionCorrConfig
        
        alignFilePath
        alignResult

        setupMode %1=SetupA; 3=SetupC/VR
        loadMapFromFile %Mainly for SetupC mode
        blankingstructureFileList %Mainly for SetupC mode
        
        responseOption
        responseMaxOption
        localCorrelationOption
        SetupCAnatomyOption = struct('skipping',5,...
                                     'offset',0);
        SetupCResponseOption = struct('skipping',5,...
                                      'lowerPercentile',25,...
                                      'offset',0);
        SetupCMaxResponseOption=struct('skipping',5,...
                                       'lowerPercentile',25,...
                                       'slidingWindowSize',3,...
                                       'offset',0);
        SetupCCorrOption= struct('skipping',5,...
                                 'tileSize',16 );
        
        roiDir
        jroiDir
        maskDir
        precalculatedMapDir

        planeNum
        
        trialOptionRaw
        alignToTemplate
        mapsAfterLoading
        loadTemplateRoi
        roiTemplateFilePath

        roiFileIdentifier    
       

        registerWithBunwarpj = false
        transformParam
        referenceTrialIdx
        transformationName
        calculatedTransformationsIdx
        calculatedTransformationsList
        
        TransformationTooltip
        
        stackModel
    end 
    
    properties (SetAccess = private, SetObservable = true)
        anatomyConfig
        alignConfig
    end
    
    methods
        function self = NrModel(varargin)
            pa = inputParser;
            addParameter(pa,'rawDataDir','',@ischar);
            addParameter(pa,'rawFileList','',@iscell);
            addParameter(pa,'resultDir','',@ischar);
            addParameter(pa,'precalculatedMapDir','',@ischar);    
            defaultExpInfo.frameRate = 1;
            defaultExpInfo.nPlane = 1;
            defaultExpInfo.mapSize = [512, 512];
            addParameter(pa,'expInfo',defaultExpInfo,@isstruct);
            % addParameter(pa,'alignFilePath','',@ischar)
            addParameter(pa,'roiDir','',@ischar);

            defaultTrialOptionRaw = struct('subtractScan',false,...
                                'noSignalWindow',[1 12], ...
                                'intensityOffset',-30);
            addParameter(pa,'trialOptionRaw',defaultTrialOptionRaw, ...
                         @isstruct);
            
            
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
            addParameter(pa,'TransformationTooltip',struct(),@isstruct);
            %SetupCTab map options
            defaultSetupCAnatomyOption = struct('skipping',5,...
                                                  'offset',0  );
            defaultSetupCResponseOption = struct('skipping',5,...
                                              'lowerPercentile',25,...
                                              'offset',0);
            defaultSetupCMaxResponseOption = struct('skipping',5,...
                                              'lowerPercentile',25,...
                                              'slidingWindowSize',3,...
                                              'offset',0);
            defaultSetupCCorrOption = struct('skipping',5,...
                                              'tileSize',16 );
            addParameter(pa,'SetupCAnatomyOption',defaultSetupCAnatomyOption, ...
                         @isstruct);
            addParameter(pa,'SetupCResponseOption',defaultSetupCResponseOption, ...
                         @isstruct);
            addParameter(pa,'SetupCMaxResponseOption',defaultSetupCMaxResponseOption, ...
                         @isstruct);
            addParameter(pa,'SetupCCorrOption',defaultSetupCCorrOption, ...
                         @isstruct);


            %SetupMode parameter
            defaultSetupModeParameter = 1;
            addParameter(pa, 'SetupMode',defaultSetupModeParameter, @isinteger);
            
            defaultRoiFileIdentifier ="_RoiArray";
            
            addParameter(pa, 'roiFileIdentifier',defaultRoiFileIdentifier, @isstring);

            parse(pa,varargin{:})
            pr = pa.Results;
            
            self.trialArray = trialMvc.TrialModel.empty();
            
            self.expInfo = pr.expInfo; % expInfo.nPlane is the total number of planes in the data

            self.setupMode=pr.SetupMode;
            
            self.rawDataDir = pr.rawDataDir;
            self.rawFileList = pr.rawFileList;
            self.resultDir = pr.resultDir;
            self.precalculatedMapDir=pr.precalculatedMapDir;
            
            self.alignResult = cell(1,pr.expInfo.nPlane);
            
            if ~isempty(pr.roiDir)
                self.roiDir = pr.roiDir;
            else
                self.roiDir = self.getDefaultDir('roi');
            end
            
        
            self.roiFileIdentifier=pr.roiFileIdentifier;
            self.maskDir = self.getDefaultDir('mask');

            self.trialOptionRaw = pr.trialOptionRaw;
            self.responseOption = pr.responseOption;
            self.responseMaxOption = pr.responseMaxOption;
            self.SetupCAnatomyOption=pr.SetupCAnatomyOption;
            self.SetupCResponseOption=pr.SetupCResponseOption;
            self.SetupCCorrOption=pr.SetupCCorrOption;
              
            self.mapsAfterLoading = {};
            self.loadTemplateRoi = false;
            self.roiTemplateFilePath = '';
            
            self.planeNum = 1; % The plane number for loading file

            % Bunwarpj
            self.referenceTrialIdx = 1;
            self.transformParam = Bunwarpj.TransformParam();
            self.TransformationTooltip=struct();
        end
        
        function importRawData(self,expInfo,rawDataDir,rawFileList,resultDir)
            self.expInfo = expInfo;
            self.rawDataDir = rawDataDir;
            self.rawFileList = rawFileList;
            self.resultDir = resultDir;
        end
        
        function processRawData(self,varargin)
            pa = inputParser;
            addParameter(pa,'subtractScan',false);
            addParameter(pa,'noSignalWindow',1);
            addParameter(pa,'mcWithinTrial',false);
            addParameter(pa,'computeAnatomy',true);
            addParameter(pa,'mcBetweenTrial',false);
            addParameter(pa,'mcBTTemplateIdx',1);
            parse(pa,varargin{:})
            pr = pa.Results;

            if pr.subtractScan % Subtract scan pattern caused by resonant scanning in x direction (setupA(Clara))
                trialOption = struct('subtractScan',true,'noSignalWindow',pr.noSignalWindow);
            else
                trialOption = {}; %
            end
            
            % Motion correction within trial
            if pr.mcWithinTrial
                % For now motion correction within trial only
                % support single plane data
                % TODO add multiplane support
                motionCorrDir = self.getDefaultDir('motion_corr');
                self.motionCorrBatch(trialOption,motionCorrDir)
            end
            
            % Compute averaged anatomy image for each trial
            if pr.computeAnatomy
                anatomyParam.trialOption = trialOption;
            
                for planeNum=1:self.expInfo.nPlane
                    self.calcAnatomyBatch(anatomyParam,planeNum);
                end
            end
            
            % Motion correction between trials
            if pr.mcBetweenTrial
                templateRawName = self.rawFileList{pr.mcBTTemplateIdx};
                for planeNum=1:self.expInfo.nPlane
                    outDir = fullfile(self.resultDir,self.alignDir);
                    self.alignTrialBatch(templateRawName,...
                                         'planeNum',planeNum,...
                                         'alignOption',{'plotFig',false},...
                                         'outDir', outDir);
                end
            end
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

        function trial = loadTrialFromList(self,fileIdx, planeNum)
            if ~exist('planeNum','var')
                planeNum = 1;
            end
            
            rawFileName = self.rawFileList{fileIdx};
            fprintf('Loading %s\n planeNum: %d\n',rawFileName, ...
                    planeNum)
            
            multiPlane = checkMultiPlane(self,planeNum);

            fileName = rawFileName;
            filePath = fullfile(self.rawDataDir, ...
                                fileName);
            trialOption = self.trialOptionRaw;
            if multiPlane
                trialOption.zrange = [planeNum inf];
                trialOption.nFramePerStep = ...
                    self.expInfo.nPlane;
                frameRate = self.expInfo.frameRate /self.expInfo.nPlane;
            else
                frameRate = self.expInfo.frameRate;
            end
            

            if self.alignToTemplate
                offsetYx = self.getTrialOffsetYx(fileIdx,planeNum);
            else            
                warning('The trial might not be aligned in X and Y!')
                offsetYx = [0,0];
            end
            
            if multiPlane
                planeString = NrModel.getPlaneString(planeNum);
                roiDir = fullfile(self.roiDir,planeString);
            else
                roiDir = self.roiDir;
            end
            
            if ~exist(roiDir)
                mkdir(roiDir)
            end

            if multiPlane
                planeString = NrModel.getPlaneString(planeNum);
                maskDir = fullfile(self.maskDir,planeString);
            else
                maskDir = self.maskDir;
            end
            
            if ~exist(maskDir)
                mkdir(maskDir)
            end

            trialOption.yxShift = offsetYx;
            trialOption.roiDir = roiDir;
            trialOption.maskDir = maskDir;
            trialOption.frameRate = frameRate;
            trialOption.loadMapFromFile= self.loadMapFromFile;
            trialOption.setupMode=self.setupMode;
            trial = self.loadTrial(filePath,trialOption);
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
            
            if ismember(tag,tagArray)
                error('Cannot get unused trial tag!')
            end
            
            trialOptionCell = helper.structToNameValPair(trialOption);
            trial = trialMvc.TrialModel('filePath',filePath,trialOptionCell{:});
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
              case 'localCorrelation'
                mapOption = self.localCorrelationOption;
              case 'SetupCAnatomy'
                mapOption = self.SetupCAnatomyOption;
              case 'SetupCResponse'
                 mapOption = self.SetupCResponseOption;
              case 'SetupCResponseMax'
                 mapOption = self.SetupCMaxResponseOption;
              case 'SetupCCorr'
                 mapOption = self.SetupCCorrOption;
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
                if strcmp(ME.identifier,['trialMvc.TrialModel:' ...
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
                  case 'trialMvc.TrialModel:mapTypeError','trialMvc.TrialModel:windowValueError'
                    self.view.displayError(ME);
                    return
                end
                rethrow(ME)
            end
                
        end

        function LoadMapsFromFileCurrTrial(self,TempMapFolder)
            MapFiles=dir(strcat(TempMapFolder,"/*.mat"));
            [~,idx] = sort([MapFiles.datenum]);
            MapFiles = MapFiles(idx);
            trial = self.getCurrentTrial();
            for i=1:length(MapFiles)
                trial.LoadAndAddMapFromFile(fullfile(MapFiles(i).folder,MapFiles(i).name));
            end
            %trial.LoadAndAddMapFromFile(MapFiles);
            
        end

        
        function motionCorrBatch(self,trialOption,outDir,fileIdx)
        % MOTIONCORRBATCH motion correction within trial
        %      multiplane not yet implemented
            self.motionCorrConfig.outDir = outDir;
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList;
            end
            batch.motionCorrFromFile(self.rawDataDir,rawFileList,trialOption,outDir)
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
                    planeString = NrModel.getPlaneString(planeNum);
                    outSubDir = fullfile(outDir,planeString);
                    if ~exist(outSubDir,'dir')
                        mkdir(outSubDir)
                    end
                    trialOption.nFramePerStep = self.expInfo.nPlane;
                    trialOption.zrange = [planeNum,inf];
                else
                    error(['Please specify plane number for' ...
                           ' multiplane data!']);
                end
            else
                outSubDir = outDir;
            end

            
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList;
            end
            
            binConfig = batch.binMovieFromFile(self.rawDataDir, ...
                                               rawFileList, ...
                                               outSubDir,...
                                               param.shrinkFactors,...
                                               param.depth,...
                                               trialOption);
            binConfig.outDir = outDir;
            binConfig.trialOption = param.trialOption;
            self.binConfig = binConfig;
            % timeStamp = helper.getTimeStamp();
            % configFileName = ['binConfig-' timeStamp '.json'];
            configFileName = 'binConfig.json';
            configFilePath = fullfile(outDir,configFileName);
            helper.saveStructAsJson(binConfig,configFilePath);
        end
        
        function readBinConfig(self,metaFilePath)
            self.binConfig = jsondecode(fileread(metaFilePath));
        end
        
        function calcAnatomyBatch(self,param,planeNum,fileIdx)
            outDir = self.getDefaultDir('anatomy');
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

            outSubDir = self.appendPlaneDir(outDir, planeNum);
            if ~exist(outSubDir,'dir')
                mkdir(outSubDir)
            end

            trialOption = param.trialOption;
            if self.expInfo.nPlane > 1
                trialOption.nFramePerStep = self.expInfo.nPlane;
                trialOption.zrange = [planeNum,inf];
            end
            [~,filePrefix] = batch.calcAnatomyFromFile(self.rawDataDir, ...
                                                        rawFileList,...
                                                        outSubDir, ...
                                                        trialOption);
            
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

        function alignResult = alignTrialBatch(self,templateRawName,varargin)
            pa = inputParser;
            addParameter(pa,'planeNum',1,@isnumeric);
            addParameter(pa,'fileIdx','all',@(x) ischar(x)|ismatrix(x));
            addParameter(pa,'alignOption',{},@iscell);
            addParameter(pa, 'outDir', '', @ischar);
            parse(pa,varargin{:})
            pr = pa.Results;
            
            outFileName = 'alignResult.mat';
            outDir = pr.outDir;
            if ~exist(outDir,'dir')
                mkdir(outDir)
            end

            anatomyPrefix = self.anatomyConfig.filePrefix;
            templateName = iopath.modifyFileName(templateRawName, ...
                                           anatomyPrefix,'','tif');
            

            if ischar(pr.fileIdx)
                rawFileList = self.rawFileList;
            else
                rawFileList = self.rawFileList(pr.fileIdx);
            end

            % TODO deal with error that no anatomy files found
            % TODO deal with no anatomyConfig loaded
            
            inDir = self.appendPlaneDir(self.getDefaultDir('anatomy'), pr.planeNum);
            outSubDir = self.appendPlaneDir(outDir, pr.planeNum);
            if ~exist(outSubDir,'dir')
                mkdir(outSubDir)
            end
            
            anatomyFileList = iopath.modifyFileName(rawFileList, ...
                                                    anatomyPrefix, ...
                                                    '','tif');
            stackFileName = iopath.modifyFileName(outFileName, ...
                                                  'stack_','','tif');
            stackFilePath = fullfile(outSubDir,stackFileName);
            alignResult = batch.alignTrials(inDir,...
                                            anatomyFileList, ...
                                            templateName,...
                                            'stackFilePath',...
                                            stackFilePath,...
                                            pr.alignOption{:});
            
            alignResult.anatomyPrefix = anatomyPrefix;
            alignResult.templateRawName = templateRawName;

            self.alignResult{pr.planeNum} = alignResult;
            
            outFilePath = fullfile(outSubDir,outFileName);
            save(outFilePath,'alignResult')
        end
        
        function loadAlignResult(self,planeNum)
            fileName = 'alignResult.mat';
            multiPlane = self.checkMultiPlane(planeNum);
            if multiPlane
                planeString = NrModel.getPlaneString(planeNum);
                filePath = fullfile(self.resultDir,self.alignDir,planeString,...
                                    fileName);
            else
                filePath = fullfile(self.resultDir,self.alignDir,fileName);
            end
            foo = load(filePath);
            self.alignResult{planeNum} = foo.alignResult;
        end
        
        function arrangeTrialTable(self)
            trialTable = batch.getTrialTable(self.rawFileList,self.expInfo.odorList);
            trialTable = batch.addTrialNum(trialTable);
            self.trialTable = trialTable;
        end
        
        function removeTrialFromTable(self, fileIdxList)
            rowLogic = ismember(self.trialTable.fileIdx, fileIdxList);
            self.trialTable(rowLogic,:) = [];
        end
        
        function [mapArray,varargout] = calcMapBatch(self,mapType,mapOption,varargin)
            pa = inputParser;
            addParameter(pa,'trialOption',[]);
            addParameter(pa,'planeNum',1,@isnumeric);
            addParameter(pa,'sortBy','none',@ischar);
            addParameter(pa,'odorDelayList',[],@ismatrix);
            addParameter(pa,'saveMap',false);
            addParameter(pa,'outFileType','mat',@ischar);
            addParameter(pa,'fileIdx',0,@ismatrix);
            parse(pa,varargin{:})
            pr = pa.Results;
            planeNum = pr.planeNum;
            multiPlane = self.checkMultiPlane(planeNum);
                
            trialOption = pr.trialOption;

            inSubDir = self.rawDataDir;
            inFileList = self.rawFileList;
            if pr.fileIdx
                inFileList = inFileList(pr.fileIdx);
            end
            if multiPlane
                trialOption.frameRate = self.expInfo.frameRate/ ...
                                        self.expInfo.nPlane;
                trialOption.zrange = [planeNum inf];
                trialOption.nFramePerStep = self.expInfo.nPlane;
            else
                trialOption.frameRate = self.expInfo.frameRate;
            end

            delayList = [];
            if pr.saveMap
                if strcmp(mapType, 'response')
                    outDir = self.getDefaultDir('response_map');
                elseif strcmp(mapType, 'responseMax')
                    outDir = self.getDefaultDir('response_max_map');
                end
                
                if ~exist(outDir,'dir')
                    mkdir(outDir)
                end
                
                if multiPlane
                    outSubDir = fullfile(outDir, ...
                                NrModel.getPlaneString(planeNum));
                    if ~exist(outSubDir,'dir')
                        mkdir(outSubDir)
                    end
                else
                    outSubDir = outDir;
                end
            else
                outSubDir = [];
            end
                
            mapArray = batch.calcMapFromFile(inSubDir,...
                                             inFileList,...
                                             mapType,...
                                             'mapOption',mapOption,...
                                             'windowDelayList',delayList,...
                                             'trialOption',trialOption,...
                                             'outDir',outSubDir,...
                                             'outFileType',pr.outFileType);
        end
        
        function offsetYx = getTrialOffsetYx(self,fileIdx,planeNum)
        % GETTRIALOFFSETYX get trial offset in y and x axis by
        % matching file name to the alignment result file list
            if isempty(self.alignResult{planeNum})
                try
                    self.loadAlignResult(planeNum);
                catch ME
                    display('Cannot load alignment result!')
                    rethrow ME
                end
            end
            alignResult = self.alignResult{planeNum};
            
            rawFileName = self.rawFileList{fileIdx};
            anatomyPrefix = alignResult.anatomyPrefix;
            anatomyFileName = ...
                iopath.modifyFileName(rawFileName, ...
                                      anatomyPrefix,'','tif');
            offsetYx = self.getOffsetYx(alignResult, anatomyFileName);
        end
        
        function offsetYx = getOffsetYx(self, alignResult, anatomyFileName)
            inFileList = alignResult.inFileList;
            idx = find(strcmp(inFileList,anatomyFileName));
            if isempty(idx)
                msg = ['Cannot find offset value in the aligment ' ...
                       'result for file: ' anatomyFileName];
                error(msg);
            else
                offsetYx = alignResult.offsetYxMat(idx,:);
            end
        end
                
        function [timeTraceMat,roiArr] = extractTimeTrace(self, fileIdx,...
                                                            varargin)
            pa = inputParser;
            addRequired(pa,'fileIdx');
            addParameter(pa,'roiArr', []);
            addParameter(pa,'roiFilePath', []);
            addParameter(pa,'planeNum', 1);
            
            parse(pa,fileIdx, ...
                  varargin{:})
            pr = pa.Results;
            
            planeNum = pr.planeNum;
            
            multiPlane = self.checkMultiPlane(planeNum);
            
            traceDir = fullfile(self.resultDir,'time_trace');
            
            if multiPlane
                planeString = NrModel.getPlaneString(planeNum);
                traceDir = fullfile(traceDir,planeString);
            end
            
            if ~exist(traceDir,'dir')
                mkdir(traceDir)
            end
            
            disp(sprintf('Extract time trace ...'))
            disp(sprintf('Data file: #%d, %s', fileIdx, self.rawFileList{fileIdx}))
            trial = self.loadTrialFromList(fileIdx,planeNum);
            
            if ~isempty(pr.roiArr)
                disp('ROI from stack')
                trial.replaceRoiArr(pr.roiArr)
            else
                if ~exist(pr.roiFilePath,'file')
                    error(sprintf('ROI file %s does not exists!',roiFilePath))
                end
                disp(sprintf('ROI file: %s', roiFilePath))
                trial.loadRoiArr(pr.roiFilePath);
            end
            
            [timeTraceMat,roiArr] = trial.extractTimeTraceMat();
            
            dataFileBaseName = trial.name;
            resFileName = [dataFileBaseName '_traceResult.mat'];
            resFilePath = fullfile(traceDir,resFileName);
            traceResult.timeTraceMat = timeTraceMat;
            traceResult.roiArr = roiArr;
            traceResult.roiFilePath = pr.roiFilePath;
            traceResult.rawFilePath = trial.filePath;
            save(resFilePath,'traceResult')
        end
        
        function extractTimeTraceBatch(self, fileIdxList, ...
                                       varargin)
            pa = inputParser;
            addRequired(pa,'fileIdxList');
            addParameter(pa,'roiArrStack', []);
            addParameter(pa,'roiFileList', []);
            addParameter(pa,'planeNum', 1);
            addParameter(pa,'plotTrace', true);
            
            parse(pa,fileIdxList, ...
                  varargin{:})
            pr = pa.Results;
            
            if pr.plotTrace
                timeTraceFig = figure();
                nrow = 4;
                ncol = ceil(length(fileIdxList)/4);
            end

            for k=1:length(fileIdxList)
                fileIdx = fileIdxList(k);
                
                if ~isempty(pr.roiArrStack)
                    roiArr = pr.roiArrStack(k);
                    [timeTraceMat,roiArr] = self.extractTimeTrace(fileIdx,...
                                              'roiArr', roiArr,...
                                              'planeNum', pr.planeNum);
                else
                    roiFilePath = pr.roiFileList{k};
                    [timeTraceMat,roiArr] = self.extractTimeTrace(fileIdx,...
                                              'roiFilePath', roiFilePath,...
                                              'planeNum', pr.planeNum);
                end
                
                if pr.plotTrace
                    figure(timeTraceFig)
                    subplot(nrow,ncol,k)
                    imagesc(timeTraceMat)
                end
            end
        end

        function SetupCExtractTracesDfoverf(self)
            planeString = NrModel.getPlaneString(self.planeNum);
            CalculatedTransformationName= self.calculatedTransformationsList(self.calculatedTransformationsIdx);
            RoisStruc= load(fullfile(self.resultDir,"BUnwarpJ",CalculatedTransformationName,"Rois.mat"));
            TempCellArray=struct2cell(RoisStruc.RoiArray);
            blankingPath=fullfile(self.resultDir,strcat(nameParts{1},'_',nameParts{2},'_blankingstruct.mat'));
            if exist(blankingPath)
                load(blankingPath);
                framesToBlank=[blankingstruct.blankingdx blankingstruct.blankingdy];
                framesToBlank= unique(framesToBlank);
                temprawfile(:,:,framesToBlank)= [];
            end
            self.BUnwarpJRoiCellarray=squeeze(TempCellArray(1,:,:));
            NameCellArray=squeeze(TempCellArray(2,:,:));
            NameCellArray=cellstr(NameCellArray);
            disp("Start calculating cellTraces");
            mkdir(fullfile(self.resultDir,'cellTraces',planeString,CalculatedTransformationName{1}));  
            for i=1:length(self.rawFileList)
                
                AquiName=strsplit(self.rawFileList{i},'.');
                outputFolder=(fullfile(self.resultDir,'cellTraces',planeString,CalculatedTransformationName{1},AquiName{1}));
                mkdir(outputFolder);
                index=find(contains(NameCellArray,AquiName{1}));
                disp("load stack");
                tempRawFile=load(fullfile(self.rawDataDir,self.rawFileList{index}));
                disp("loading done");
                %tempRawFile=load('C:\Data\temp\2020Oct13\registeredStacks\2020Oct13_003_neuRoiIO-test.mat');
                tempRawFile=tempRawFile.stack;
                stackMin=min(tempRawFile,[],'all');
                tempRawFile=tempRawFile-stackMin;
                AquiRois=self.BUnwarpJRoiCellarray{index};
                maxRoiTag=AquiRois(length(AquiRois)).tag;
                frameCount=size(tempRawFile);
                mapSize=frameCount(1:2);
                frameCount=frameCount(3);
                %OutputMatrix=zeros(frameCount,maxRoiTag);
                OutputMatrix=[];
                oldTag=1;
                for j=1:length(AquiRois)
                    tempRoi=AquiRois(j);
                    newtag=tempRoi.tag;
                    difTags=uint8(newtag-oldTag);
                    if difTags>1
                        for k=1:(difTags-1)
                            OutputMatrix(:,end+1)=zeros(frameCount,1);
                        end
                    end
                    mask = tempRoi.createMask(mapSize);
                    [maskIndX maskIndY] = find(mask==1);
                    roiMovie = tempRawFile(maskIndX,maskIndY,:);
                    timeTraceRaw = squeeze(mean(mean(roiMovie,1),2));
                    OutputMatrix(:,end+1)=timeTraceRaw;
                    oldTag=newtag;
                end
                
                %df/f calculations
                fZeroRawPercentile=prctile(OutputMatrix,25,1);
                fZeroRaw=double(OutputMatrix);
                fZeroRaw(fZeroRaw> fZeroRawPercentile)=NaN;
                fZeroRaw =mean(fZeroRaw,1,"omitnan");
                offset=0;
                OutputMatrix=(OutputMatrix-fZeroRaw)./(fZeroRaw-offset);



                
                %save("C:\Data\temp\RoiTest.mat",'OutputMatrix');
                save(fullfile(outputFolder,AquiName{1}),'OutputMatrix');
            end
            disp("cellTraces done");
        end
        
        function multiPlane = checkMultiPlane(self,planeNum)
            multiPlane = false;
            if isfield(self.expInfo,'nPlane')
                nPlane = self.expInfo.nPlane;
                if nPlane >1
                    if planeNum >= 1 && planeNum <= nPlane
                        multiPlane = true;
                    else
                        msg = sprintf(['Please specify the plane'...
                                       'numberbetween 1 and %d!'], ...
                                      nPlane);
                        error(msg);
                    end
                else
                    if planeNum > 1
                        msg = sprintf(['No multi-plane data for'...
                                      ' plane %d'],planeNum);
                        error(msg);
                    end
                end
            end
        end

        function resultDir = get.resultDir(self)
            % Handle using the experiment across os platforms
            resultDir = helper.normalizePath(self.resultDir);
        end
        
        function dd = getDefaultDir(self,dirName)
            dirNameList = {'binned', 'anatomy', 'alignment',...
                           'response_map', 'response_max_map'...
                           'roi','mask',...
                           'motion_corr','df_rgb',...
                           'stardist_mask','trial_stack',...
                           'bunwarpj'};
            if ismember(dirName, dirNameList)
                if strcmp(dirName, 'bunwarpj')
                    altDir = fullfile(self.resultDir, 'BUnwarpJ');
                    if exist(altDir, 'dir')
                        dd = altDir; % compatible for bUnwarpJ results for version before commit d56f6df
                    else
                        dd = fullfile(self.resultDir,dirName);
                    end
                else
                    dd = fullfile(self.resultDir,dirName);
                end
            else
                error('Directory name not in list!')
            end
        end
        
        function subDir = appendPlaneDir(self, parentDir, planeNum)
            if self.expInfo.nPlane > 1
                planeString = NrModel.getPlaneString(planeNum);
                subDir = fullfile(parentDir,planeString);
            else
                subDir = parentDir;
            end
        end
        
        function fp = getDefaultFile(self,fileName)
            switch fileName
              case 'experiment'
                fileName = sprintf('experiment_%s.mat',self.expInfo.name);
                fp = fullfile(self.resultDir,fileName);
            end
        end
        
        function fileList = getFileList(self,fileType,fileIdx)
            if exist('fileIdx','var')
                rawFileList = self.rawFileList(fileIdx);
            else
                rawFileList = self.rawFileList;
            end
            
            if strcmp(fileType, 'raw')
                fileList = rawFileList;
            elseif strcmp(fileType, 'trial')
                fileList = strrep(rawFileList, '.tif', '');
            else
                switch fileType
                  case 'anatomy'
                    prefix = self.anatomyConfig.filePrefix;
                    appendix = '';
                    ext = 'tif';
                  case 'response'
                    prefix = 'response_';
                    appendix = '';
                    ext = 'mat';
                  case 'responseMax'
                    prefix = 'responseMax_';
                    appendix = '';
                    ext = 'mat';
                end
                fileList = iopath.modifyFileName(rawFileList, ...
                                                 prefix,appendix,ext);
            end
        end
        
        function varargout = getSelectedFileList(self, fileType)
            if length(self.selectedFileIdx)
                fileList = self.getFileList(fileType, self.selectedFileIdx);
                idxList = self.selectedFileIdx;
            else
                fileList = self.getFileList(fileType);
                idxList = 1:length(self.rawFileList);
            end
            
            varargout{1} = fileList;
            if nargout == 2
                varargout{2} = idxList;
            end
        end

        
        function saveExperiment(self,filePath)
            save(filePath,'self')
        end
        
        function s = saveobj(self)
            for fn = fieldnames(self)' %'
                if ~strcmp(fn, 'stackModel')
                    s.(fn{1}) = self.(fn{1});
                end
            end
        end

        
        %Register trials
        function registerTrials(self)
            % Currently asume not rigid alignment was done using alignTrials
            bunwarpjDir = self.getBunwarpjDir();
            if ~exist(bunwarpjDir, 'dir')
                mkdir(bunwarpjDir);
            end
            
            trialNameList = self.getSelectedFileList('trial');
            refTrialName = self.getFileList('trial', self.referenceTrialIdx);
            [trialNameList, ~] = NrModel.removeReferenceFromList(trialNameList, refTrialName);
            
            anatomyDir = self.appendPlaneDir(self.getDefaultDir('anatomy'), self.planeNum);
            anatomyNameList = self.getSelectedFileList('anatomy');
            refAnatomyName = self.getFileList('anatomy', self.referenceTrialIdx);
            [anatomyNameList, ~] = NrModel.removeReferenceFromList(anatomyNameList, refAnatomyName);
            anatomyFileList = fullfile(anatomyDir, anatomyNameList);
            refAnatomyFile = fullfile(anatomyDir, refAnatomyName);
            
            if self.registerWithBunwarpj
                % Compute tranfromation and save as .mat
                % Bunwarpj.computeBunwarpj(anatomyFileList, refAnatomyFile,...
                %                          trialNameList, refTrialName,...
                %                          self.transformParam, offsetYxList,...
                %                          bunwarpjDir);
                nrOpticFlow.computeTransformationWrapper(anatomyFileList, refAnatomyFile,...
                                                       trialNameList, refTrialName,...
                                                       self.transformParam, bunwarpjDir);
                % This computes tranformation forward, apply it to each trial to match with reference image
                % and then compute inverse transformation, apply it to reference to match with each trial
            else
                % TODO currently this is a work around to create transformation
                % as identity transformation
                Bunwarpj.saveIdentityTransform(anatomyFileList, refAnatomyFile,...
                                               trialNameList, refTrialName,...
                                               self.transformParam, offsetYxList,...
                                               bunwarpjDir);
            end
            
            
            if isempty(self.calculatedTransformationsList)
                self.calculatedTransformationsIdx=1;
            end
            
            self.calculatedTransformationsList{end+1} = self.transformationName;
        end

        function computeRegisteredTrialStack(self)
            disp('Compute registered trial stack...')
            bunwarpjDir = self.getBunwarpjDir();
            transformMeta = load(fullfile(bunwarpjDir, 'transformMeta.mat'));
            refTrialName = transformMeta.refTrialName;
            
            [trialNameList, trialIdxList] = self.getSelectedFileList('trial');
            transformStack = transformFunc.loadTransformStack(bunwarpjDir, trialNameList, 'forward');
            
            % Load original anatomy file list
            anatomyDir = self.appendPlaneDir(self.getDefaultDir('anatomy'), self.planeNum);
            anatomyNameList = self.getSelectedFileList('anatomy');
            refAnatomyName = self.getFileList('anatomy', self.referenceTrialIdx);
            anatomyFileList = fullfile(anatomyDir, anatomyNameList);
            refAnatomyFile = fullfile(anatomyDir, refAnatomyName);

            % For each anatomy file, apply transformation from transformInvStack to each trial
            % and save the result as registered trial stack
            trialStackDir = bunwarpjDir
            if ~exist(trialStackDir, 'dir')
                mkdir(trialStackDir)
            end

            % Open image file of reference anatomy
            refAnatomy = movieFunc.readTiff(refAnatomyFile);

            imageSize = size(refAnatomy);
            % registered stack as a three dimensional array
            registeredAnatomyStack = zeros([imageSize, length(anatomyFileList)], 'uint16');
            for i=1:length(anatomyFileList)
                anatomyFile = anatomyFileList{i};
                trialAnatomy = movieFunc.readTiff(anatomyFile);
                registeredAnatomyStack(:,:,i) = nrOpticFlow.applyTransformation(trialAnatomy, transformStack(i));
            end

            % Save registered anatomy stack
            movieFunc.saveTiff(registeredAnatomyStack, fullfile(trialStackDir, 'registeredAnatomyStack.tif'));
            disp('Registered trial stack saved.')
        end
            
        function bunwarpjDir = getBunwarpjDir(self)
            bunwarpjDir = self.appendPlaneDir(fullfile(self.getDefaultDir('bunwarpj'),...
                                                       self.transformationName),...
                                              self.planeNum);
        end
        
        function bunwarpjDir = getSelectedBunwarpjDir(self)
            transfName = self.calculatedTransformationsList{self.calculatedTransformationsIdx};
            bunwarpjDir = self.appendPlaneDir(fullfile(self.getDefaultDir('bunwarpj'),...
                                                       transfName),...
                                              self.planeNum);
        end
        
        function templateRoiArr = loadTemplateRoiArr(self, refTrialName)
            roiDir = self.appendPlaneDir(self.getDefaultDir('roi'), self.planeNum);
            roiFile = fullfile(roiDir, iopath.modifyFileName(refTrialName,'',...
                                                             self.roiFileIdentifier,"mat"));
            if ~isfile(roiFile)
                error(sprintf("Cannot find roi file for reference trial. %s", roiFile));
                return
            end
            foo = load(roiFile);
            templateRoiArr = foo.roiArr;
        end
                
        function inspectStack(self)
            bunwarpjDir = self.getSelectedBunwarpjDir();
            transformMeta = load(fullfile(bunwarpjDir, 'transformMeta.mat'));
            refTrialName = transformMeta.refTrialName;
            
            [trialNameList, trialIdxList] = self.getSelectedFileList('trial');

            anatomyDir = self.appendPlaneDir(self.getDefaultDir('anatomy'), self.planeNum);
            anatomyFileList = self.getSelectedFileList('anatomy');
            anatomyStack = batch.loadStack(anatomyDir,anatomyFileList);
            
            responseDir = self.appendPlaneDir(self.getDefaultDir('response_map'), self.planeNum);
            if exist(responseDir, 'dir')
                responseFileList = self.getSelectedFileList('response');
                responseStack = batch.loadStack(responseDir,responseFileList);
            else
                responseStack = self.calcResponseMapArray(true);
            end

            responseMaxDir = self.appendPlaneDir(self.getDefaultDir('response_max_map'), self.planeNum);
            if exist(responseMaxDir, 'dir')
                responseMaxFileList = self.getSelectedFileList('responseMax');
                responseMaxStack = batch.loadStack(responseMaxDir,responseMaxFileList);
            else
                responseMaxStack = self.calcResponseMaxMapArray(true);
            end
            
            % TODO apply CLAHE
            % for i=1:size(anatomyArray,3)
            %     anatomyArray(:,:,i)=adapthisteq(uint8(squeeze(anatomyArray(:,:,i))),"NumTiles",[8 8],'ClipLimit',0.02);
            % end

            transformStack = transformFunc.loadTransformStack(bunwarpjDir, trialNameList, 'forward');
            transformInvStack = transformFunc.loadTransformStack(bunwarpjDir, trialNameList, 'inverse');
            
            roiArrStackFile = fullfile(bunwarpjDir,"roiArrStack.mat");
            if isfile(roiArrStackFile)
                foo = load(roiArrStackFile);
                roiArrStack = foo.roiArrStack;
                doSummarizeRoiTags = false;
            else
                templateRoiArr = self.loadTemplateRoiArr(refTrialName);
                roiArrStack = transformFunc.transformRoiArrStack(templateRoiArr, transformInvStack);
                doSummarizeRoiTags = true;
            end
            
            self.stackModel = trialStack.TrialStackModel(trialNameList,...
                                                         anatomyStack,...
                                                         responseStack,...
                                                         responseMaxStack,...
                                                         'nrModel', self,...
                                                         'roiArrStack', roiArrStack,...
                                                         'transformStack', transformStack,...
                                                         'transformInvStack', transformInvStack,...
                                                         'doSummarizeRoiTags', doSummarizeRoiTags,...
                                                         'trialIdxList', trialIdxList,...
                                                         'roiDir', bunwarpjDir,...
                                                         'planeNum', self.planeNum);
        end
        
        function responseArray = calcResponseMapArray(self, saveMap)
            fileIdx = self.selectedFileIdx;
            planeNum = self.planeNum;
            mapType = 'response';
            mapOption = self.responseOption;
            trialOption = self.trialOptionRaw;
            responseArray= self.calcMapBatch(mapType,mapOption,...
                                             'trialOption',trialOption,...
                                             'sortBy','odor',...
                                             'planeNum',planeNum,...
                                             'fileIdx',fileIdx,...
                                             'saveMap', saveMap,...
                                             'outFileType', 'mat');
        end

        function responseMaxArray = calcResponseMaxMapArray(self, saveMap)
            fileIdx = self.selectedFileIdx;
            planeNum = self.planeNum;
            mapType = 'responseMax';
            mapOption = self.responseMaxOption;
            trialOption = self.trialOptionRaw;
            responseMaxArray= self.calcMapBatch(mapType,mapOption,...
                                                'trialOption',trialOption,...
                                                'sortBy','odor',...
                                                'planeNum',planeNum,...
                                                'fileIdx',fileIdx,...
                                                'saveMap', saveMap,...
                                                'outFileType', 'mat');
        end
        
        function NewParameter= CreateRawFileListInParameter(self, OldParameter, transformationName)
            NewParameter=OldParameter;
            TifFolder= fullfile(self.resultDir,"BUnwarpJ",transformationName,OldParameter.Plane,"*.tif");
            TifFiles=dir(TifFolder);
            TifFilesCell=struct2cell(TifFiles);
            FileParts=cellfun(@(x) strsplit(x, "_"),TifFilesCell(1,:),'UniformOutput',false);
            
            JointParts=cellfun(@(x) convertStringsToChars(strcat(strjoin(x(2:4),"_"),".mat")),FileParts,'UniformOutput',false);
            NewParameter.Rawfile_List=JointParts';
            
        end

        function LoadCalculatedTransformation(self)
            files= dir(fullfile(self.resultDir,"BUnwarpJ"));
            dirFlags = [files.isdir];
            subFolders = files(dirFlags);
            subFolderNames = {subFolders(3:end).name};
            self.calculatedTransformationsList=subFolderNames;
        end

        function UpdateTransformationTooltipValue(self)
            CalculatedTransformationName= self.calculatedTransformationsList(self.calculatedTransformationsIdx);
            TransformationPath=fullfile(self.resultDir,"BUnwarpJ",CalculatedTransformationName,"TransformationParameters.mat");
            if isfile(TransformationPath)
                parameterStruc= load(TransformationPath);
                parameterStruc=parameterStruc.TransformationParameters;
                self.TransformationTooltip = helper.deconvoluteStruct(parameterStruc);
            else
                self.TransformationTooltip=struct("No_parameters_file_found","NoData");
            end
        end
        
        function mapSize = getMapSize(self)
            if isfield(self.expInfo, 'mapSize')
                mapSize = self.expInfo.mapSize
            else
                disp('Loading 1st trial to determine mapSize')
                fileIdx = 1;
                planeNum = 1;
                trial = self.loadTrialFromList(fileIdx,planeNum);
                mapSize = trial.getMapSize();
                self.trialArray(end) = []; % delete the temporarily loaded trial
                self.expInfo.mapSize = mapSize;
            end
        end

        
    end

    methods (Static)
        function obj = loadobj(s)
            if isstruct(s)
                obj = NrModel();
                
                for fn = fieldnames(s)'
                    fName = fn{1};
                    if isprop(obj, fName)
                        if strcmp(fName, 'trialArray')
                            if isempty(s.trialArray)
                                self.trialArray = trialMvc.TrialModel.empty();
                            else
                                self.trialArray = s.trialArray;
                            end
                        else
                            obj.(fName) = s.(fName);
                        end
                    else
                        warning(sprintf("Property %s is not in NrModel.", fName));
                    end
                end
            else
                obj = s;
            end
        end
    
        function planeString = getPlaneString(planeNum)
            planeString = sprintf('plane%02d',planeNum);
        end
        
        function [fileList, rIdx] = removeReferenceFromList(fileList, referenceFile)
            rIdx = find(strcmp(fileList, referenceFile));
            if rIdx
                fileList(rIdx) = [];
            end
        end

    end
    
end
