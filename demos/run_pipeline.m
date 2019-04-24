%% step 1 Add path
addpath('../')
%% step 2 Clear variables
clear all
%% step 3 Create experiment database
expConfig.odorList = {'ala','trp','ser','acsf','tca','tdca','gca''spont'};
expConfig.nTrial = 3;
expConfig.name = '2019-03-15-OBDp';
expConfig.rawFileList = {'20190315_BH18_29dfp_Dp_z80um_s1_o1ala_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s1_o2trp_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s1_o3ser_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s1_o4acsf_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s2_o1trp_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s2_o2ser_002_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s2_o3ala_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s2_o4acsf_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s3_o1ser_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s3_o2trp_001_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s3_o3ala_002_.tif',...
                    '20190315_BH18_29dfp_Dp_z80um_s3_o4acsf_001_.tif'};

% expConfig.rawFileList = expConfig.rawFileList(1:2);
% TODO Frame rate of acquisition read from file
expConfig.frameRate = 30;

intensityOffset = -100;
% IMPORTANT the parameters of response time dF/F map are in unit
% second now!! not frame number
expConfig.responseOption = struct('offset',intensityOffset,...
                                  'fZeroWindow',[1 5],...
                                  'responseWindow',[15 20]);

expConfig.responseMaxOption = struct('offset',intensityOffset,...
                                     'fZeroWindow',[1 5],...
                                     'slidingWindowSize',3);
% expConfig.rawFileList = expConfig.rawFileList(1);
%% step 4 Define file path
%% please set expConfig.resultDir, expConfig.rawDataDir,
%% expConfig.binnedDir according to your folder names

dataRootDir = '/media/hubo/Bo_FMI/Ca_imaging/';
resultRootDir = '/home/hubo/Projects/Ca_imaging/results';

expConfig.resultDir = fullfile(resultRootDir,expConfig.name);

expConfig.rawDataDir = fullfile(dataRootDir,'raw_data',expConfig.name);

expConfig.binnedDir = fullfile(dataRootDir,'processed_data', ...
                               expConfig.name,'binned_movie');
% expConfig.binnedDir = fullfile(resultRootDir,expConfig.name,'binned_movie');
if ~exist(expConfig.binnedDir)
    mkdir(expConfig.binnedDir)
end

expConfig.anatomyDir = fullfile(resultRootDir,expConfig.name,'anatomy_map');
if ~exist(expConfig.anatomyDir)
    mkdir(expConfig.anatomyDir)
end

expConfig.alignDir = fullfile(resultRootDir,expConfig.name,'alignment');
if ~exist(expConfig.alignDir)
    mkdir(expConfig.alignDir)
end

expConfig.roiDir = fullfile(resultRootDir,expConfig.name,'roi');
if ~exist(expConfig.roiDir)
    mkdir(expConfig.roiDir)
end



% Parameters for binning
shrinkZ = 5;
expConfig.binParam.shrinkFactors = [1, 1, shrinkZ];
% Parameters for preprocessing of raw data
process = true;
noSignalWindow = [1 12];
% Binned file names
expConfig.binnedFileList = cellfun(@(x)iopath.getBinnedFileName(x,...
                                                  expConfig.binParam.shrinkFactors),...
                                   expConfig.rawFileList,'Uniformoutput',false);
% Anatomy file names
expConfig.anatomyFileList=cellfun(@(x)iopath.getAnatomyFileName(x),...
                                  expConfig.binnedFileList,...
                                  'Uniformoutput',false);
% Alignment file names
templateInd = 6;
alignFileName = sprintf('regResult_amino_acid_template%d.mat',templateInd);
expConfig.alignFilePath = fullfile(expConfig.alignDir,alignFileName);

%% step 5 Binning raw moive
% TODO deal with file not exist in TrialModel
process = true;
noSignalWindow = [1 12];
depth = 8;
batch.binMovieFromFile(expConfig.rawDataDir, ...
                       expConfig.rawFileList, ...
                       expConfig.binParam.shrinkFactors,...
                       expConfig.binnedDir,...
                       depth,...
                       'process',true, ...
                       'noSignalWindow',noSignalWindow);
%% step 6 Calculate anatomy maps (average over frames)
batch.calcAnatomyFromFile(expConfig.binnedDir, ...
                          expConfig.binnedFileList, ...
                          expConfig.anatomyDir);
%% step 7 Align trials
templateInd = 6;
alignFileName = sprintf('regResult_amino_acid_template%d.mat',templateInd);
expConfig.alignFilePath = fullfile(expConfig.alignDir,alignFileName);

plotFig = false;
climit = [0 0.4];
debug = true;
regResult = batch.alignTrials(expConfig.anatomyDir,...
                              expConfig.anatomyFileList, ...
                              templateInd,expConfig.alignFilePath,...
                              plotFig,climit,debug);
regResult.offsetYxMat
%% step 8 Open NeuRoi GUI (you can skip step 5-7 has been run previously
%% and jump to step 8)
mymodel = NrModel(expConfig);
mycon = NrController(mymodel);
mymodel.mapsAfterLoading = {'response','responseMax'};
mymodel.loadFileType = 'binned';
mymodel.processOption.process = false;
mymodel.processOption.noSignalWindow = [];
mymodel.intensityOffset = -100;

% mymodel.loadFileType = 'raw';
% mymodel.processOption.process = true;
% mymodel.processOption.noSignalWindow = [1 12];
% mymodel.intensityOffset = -20;

% Load template ROI when open trial
% roiTemplateFileName = 'modified_template_binned_x1y1z5_20190315_BH18_29dfp_Dp_z80um_s2_o4acsf_001__RoiArray.mat';
%roiTemplateFileName = 'new_roi_template_active_cells.mat';
% mymodel.roiTemplateFilePath = fullfile(mymodel.expConfig.roiDir, ...
%                                roiTemplateFileName);
% mymodel.doLoadTemplateRoi = true;
%% get dF/F from Gui
contrastLim=[0.15 0.8];
trialIdx = mymodel.currentTrialIdx;
trialContrl = mycon.trialContrlArray(trialIdx);
trialContrl.view.setContrastLim(contrastLim);
trialContrl.view.changeMapContrast(contrastLim);
trialContrl.model.saveContrastLimToCurrentMap(contrastLim);
colorbar
%% save dF/F from gui
trialIdx = mymodel.currentTrialIdx;
trialContrl = mycon.trialContrlArray(trialIdx);
frame = get(get(trialContrl.view.guiHandles.mapAxes,'children'), ...
            'cdata');
imageName = ['responseMap_' trialContrl.model.name '.svg'];
imagePath = fullfile(expConfig.resultDir,imageName);
% imwrite(frame,imagePath);
saveas(gcf,imagePath)
%% Remove single point ROIs
trial = mymodel.getCurrentTrial();
roiArray = trial.roiArray;
deleteTagArray = {};
for k = 1:length(roiArray)
    roi = roiArray(k);
    if size(roi.position,1)<2
        deleteTagArray{end+1} = roi.tag;
    end
end
% Delete point ROIs
for k=1:length(deleteTagArray)
    tag = deleteTagArray{k};
    trial.deleteRoi(tag);
end


% %% Change load file type
% mymodel.loadFileType = 'raw';
% mymodel.processOption.process = true;
% mymodel.processOption.noSignalWindow = [1 12];
% mymodel.intensityOffset = -10;

%% Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROIs in each trial
expConfig.traceDir = fullfile(expConfig.resultDir,'timeTrace');

if ~exist(expConfig.traceDir,'dir')
    mkdir(expConfig.traceDir)
end

alignFilePath = fullfile(expConfig.alignDir, ...
                         'regResult_amino_acid_template6.mat');
foo = load(alignFilePath);
offsetYxMat = foo.regResult.offsetYxMat;

trialOption = {'intensityOffset',-50,'process',true,'noSignalWindow',[1 12]};

idxRange = 1:7;
roiTemplateFileName = 'new_roi_template_active_cells.mat';
roiTemplateFilePath = fullfile(expConfig.roiDir, ...
                               roiTemplateFileName);
plotTrace = true;
sm = 10;
batch.extractTimeTraceMatFromFile(expConfig.rawDataDir,...
                                  expConfig.rawFileList(idxRange),...
                                  roiTemplateFilePath,...
                                  expConfig.traceDir,...
                                  trialOption,...
                                  offsetYxMat(idxRange,:), ...
                                  sm,...
                                  plotTrace);

%% Extract time trace with another template ROI map
idxRange = 8:12;
roiTemplateFileName = 'new_roi_template_active_cells_after_s2_o4acsf.mat';
roiTemplateFilePath = fullfile(expConfig.roiDir, ...
                               roiTemplateFileName);
plotTrace = true;
sm = 10;
batch.extractTimeTraceMatFromFile(expConfig.rawDataDir,...
                                  expConfig.rawFileList(idxRange),...
                                  roiTemplateFilePath,...
                                  expConfig.traceDir,...
                                  trialOption,...
                                  offsetYxMat(idxRange,:), ...
                                  sm,...
                                  plotTrace);


% Next step: extract traces and analyse 2019 04 08
%% Average time trace for each odor
%% Thresholding and determine response window

%% dF/F maps for all trials
responseDir = fullfile(expConfig.resultDir,'response_map');
if ~exist(responseDir,'dir')
    mkdir(responseDir)
end

inDir = expConfig.binnedDir;
inFileList = expConfig.binnedFileList;
frameRate = expConfig.frameRate/expConfig.binParam.shrinkFactors(3);
trialOption = {'frameRate',frameRate};

mapType = 'response';
mapOption = struct('offset',-30,...
                   'fZeroWindow',[1 5],...
                   'responseWindow',[11 16]);

odorList = {'ala','trp','ser', 'acsf'};
startPointList = [398 372 345 369]/30;
odorDelayList = startPointList - min(startPointList)


sortedFileTable = batch.sortFileNameByOdor(inFileList,odorList);
trialTable = batch.getWindowDelayTable(sortedFileTable,odorList,odorDelayList)

% outDir = responseDir;
% outFileType = 'mat';
outDir = [];
outFileType = 'mat';

responseArray = batch.calcMapFromFile(inDir,trialTable.FileName,...
                                      'response',...
                                      'mapOption',mapOption,...
                                      'windowDelayList',trialTable.Delay,...
                                      'trialOption',trialOption,...
                                      'outDir',outDir,...
                                      'outFileType',outFileType);
%% Plot dF/F maps
nTrialPerOdor = 3;
climit = [0 0.2];
batch.plotMaps(responseArray,trialTable,nTrialPerOdor,climit)
