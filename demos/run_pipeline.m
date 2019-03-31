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
'20190315_BH18_29dfp_Dp_z80um_s3_o4acsf_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s4_o1tdca_003_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s4_o2tca_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s4_o3gca_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s4_o4spont_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s5_01tca_002_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s5_o2tdca_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s5_o3gca_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s5_o4spont_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s6_o1tdca_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s6_o2gca_001_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s6_o3tca_002_.tif',...
'20190315_BH18_29dfp_Dp_z80um_s6_o4spont_001_.tif'};

% expConfig.rawFileList = expConfig.rawFileList(1:2);
% Frame rate of acquisition TODO in the future read from file
expConfig.frameRate = 30;
% TODO change window from frame numbers to time in second
intensityOffset = -10;
expConfig.responseOption = struct('offset',intensityOffset,...
                                  'fZeroWindow',[100 200]/5,...
                                  'responseWindow',[300 500]/5);

expConfig.responseMaxOption = struct('offset',intensityOffset,...
                                     'fZeroWindow',[100 200]/5,...
                                     'slidingWindowSize',100/5);
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
expConfig.binning.shrinkFactors = [1, 1, shrinkZ];
% Parameters for preprocessing of raw data
process = true;
noSignalWindow = [1 12];
% Binned file names
expConfig.binnedFileList = cellfun(@(x)iopath.getBinnedFileName(x,...
                                    expConfig.binning.shrinkFactors),...
                         expConfig.rawFileList,'Uniformoutput',false);
% Anatomy file names
expConfig.anatomyFileList=cellfun(@(x)iopath.getAnatomyFileName(x),...
                                  expConfig.binnedFileList,...
                                  'Uniformoutput',false);
% Alignment file names
templateInd = 9;
alignFileName = sprintf('regResult_template%d.mat',templateInd);
expConfig.alignFilePath = fullfile(expConfig.alignDir,alignFileName);

%% Binning raw moive
% TODO deal with file not exist in TrialModel
batch.binMovieFromFile(expConfig.rawDataDir, ...
                       expConfig.rawFileList(23:24), ...
                       expConfig.binning.shrinkFactors,...
                       expConfig.binnedDir,...
                       'process',true, ...
                       'noSignalWindow',noSignalWindow);
%% Calculate anatomy maps (average over frames)
batch.calcAnatomyFromFile(expConfig.binnedDir, ...
                          expConfig.binnedFileList, ...
                          expConfig.anatomyDir);
%% Align trials
plotFig = true;
climit = [0 0.4];
regResult = batch.alignTrials(expConfig.anatomyDir,...
                              expConfig.anatomyFileList, ...
                              templateInd,expConfig.alignFilePath,...
                              plotFig,climit);
regResult.offsetYxMat
%% Open NeuRoi GUI
mymodel = NrModel(expConfig);
mycon = NrController(mymodel);

%% Draw ROIs on representative trials
% TODO automate combine ROI map?
% Parameters for loading movie
zrange = 'all';
nFramePerStep = 1;
% Parameters for preprocessing
process = true;
noSignalWindow = [1 12];
% Parameters for calculating dF/F trace
intensityOffset = -10;

fileIdx = 6;
mycon.openTrial(fileIdx,'binned',...
                'intensityOffset',intensityOffset,...
                'resultDir',expConfig.roiDir);

% Add dF/F map
mymodel.responseOption.fZeroWindow = [20 35];
mymodel.responseOption.responseWindow = [60 70];
mycon.addResponseMap_Callback(1,2);


%% Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROI in each trial
%% Average time trace for each odor
%% Thresholding and determine response window
%% Calculate response maps

%% dF/F maps for all trials
