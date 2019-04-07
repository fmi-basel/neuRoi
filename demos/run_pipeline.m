%% Add path
addpath('../')
%% Clear variables
clear all
%% Create experiment database
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
% TODO change window from frame numbers to time in second
intensityOffset = -100;
expConfig.responseOption = struct('offset',intensityOffset,...
                                  'fZeroWindow',[1 5],...
                                  'responseWindow',[15 20]);

expConfig.responseMaxOption = struct('offset',intensityOffset,...
                                     'fZeroWindow',[1 5],...
                                     'slidingWindowSize',3);
% expConfig.rawFileList = expConfig.rawFileList(1);
%% Define file path
dataRootDir = '/media/hubo/Bo_FMI/Ca_imaging/';
resultRootDir = '/home/hubo/Projects/Ca_imaging/results';

expConfig.rawDataDir = fullfile(dataRootDir,'raw_data',expConfig.name);
% procDataDir =
% fullfile(dataRootDir,'processed_data',expConfig.name);

expConfig.binnedDir = fullfile(dataRootDir,'processed_data', ...
                               expConfig.name,'binned_movie');
%fullfile(resultRootDir,expConfig.name,'binned_movie');
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

%% Binning raw moive
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
%% Calculate anatomy maps (average over frames)
batch.calcAnatomyFromFile(expConfig.binnedDir, ...
                          expConfig.binnedFileList, ...
                          expConfig.anatomyDir);
%% Align trials
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
%% Open NeuRoi GUI
mymodel = NrModel(expConfig);
mycon = NrController(mymodel);
%mymodel.mapsAfterLoading = {'response','responseMax'};
mymodel.mapsAfterLoading = {};
%% Draw ROIs on representative trials
% TODO automate combine ROI map?
% Parameters for loading movie
zrange = 'all';
nFramePerStep = 1;
% Parameters for preprocessing
process = true;
noSignalWindow = [1 12];
% Parameters for calculating dF/F trace
intensityOffset = -100;

fileIdx = 5;
mycon.openTrial(fileIdx,'binned',...
                'intensityOffset',intensityOffset,...
                'resultDir',expConfig.roiDir);
% mycon.openTrial(fileIdx,'raw',...
%                 'intensityOffset',intensityOffset,...
%                 'resultDir',expConfig.roiDir);

% Add dF/F map
% mymodel.responseOption.fZeroWindow = [20 35];
% mymodel.responseOption.responseWindow = [60 70];
mymodel.responseMaxOption.slidingWindowSize = 2;
mymodel.addMapCurrTrial('response');
mymodel.addMapCurrTrial('responseMax');

% mycon.updateResponseMap_Callback(1,2);

%% Load template ROI when open trial
templateRoiFileName = 'roi_template_active_cells.mat';
mymodel.templateRoiFilePath = fullfile(mymodel.expConfig.roiDir, ...
                               templateRoiFileName);
mymodel.doLoadTemplateRoi = true;
%% Open additional file outside fileList
newFile = ['/media/hubo/Bo_FMI/Ca_imaging/processed_data/2019-03-' ...
           '15-OBDp/binned_movie/unit8_binned_x1y1z5_20190315_BH18_29dfp_Dp_z80um_s1_o2trp_001_.tif']
mycon.openAdditionalTrial(newFile,'frameRate',6)
%% Open additional file outside fileList
newFile = fullfile(expConfig.rawDataDir,'20190315_BH18_29dfp_Dp_z80um_s1_o2trp_001_.tif');
mycon.openAdditionalTrial(newFile,'frameRate',6,'process',true, ...
                          'noSignalWindow',[1 12]);

%% Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROIs in each trial

%% Average time trace for each odor
%% Thresholding and determine response window
%% Calculate response maps

%% dF/F maps for all trials
