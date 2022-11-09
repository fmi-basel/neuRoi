%% Add neuRoi root directory to path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Experiment parameters
expInfo.name = 'Chie-p1';
expInfo.frameRate = 30;
expInfo.odorList = {'AA'};
expInfo.nTrial = 1;
expInfo.nPlane = 1;

expSubDir = expInfo.name;
% Raw data
dataRootDir = '/media/hubo/Bo_FMI/Chie_data/';
% rawDataDir = fullfile(dataRootDir,'sample');
% rawFileList = {'p1_99um_AA_002__-1.tif'};
rawDataDir = fullfile(dataRootDir,'p1');
rawFileList = {'p1_99um_AA_001__.tif'};
% 'p1_99um_AA_001_.tif';...
              

% Directory for saving motion corrected movies
motionCorrDir = fullfile(rawDataDir,'motion_correction');

% Directory for saving binned movies
binDir = fullfile(rawDataDir,'binned_movie');

% Data processing configuration
% Directory for saving processing results
resultDir = fullfile(rawDataDir,'results');
%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel(rawDataDir,rawFileList,resultDir,...
                expInfo);
%% Step03 Motion correction
tic
trialOption = {}; %struct('process',true,'noSignalWindow',[1 10]);
myexp.motionCorrBatch(trialOption,motionCorrDir)
toc
%% Step04a Binning
% Bin movie parameters
binParam.shrinkFactors = [1, 1, 4];
nFramePerStep = 2;
binParam.trialOption = struct('nFramePerStep',nFramePerStep,...
                              'motionCorr',true,'motionCorrDir',motionCorrDir,...
                              'mcNFramePerStep',nFramePerStep);
% 'zrange',[1 100],...
                              
binParam.depth = 8;
tic
myexp.binMovieBatch(binParam,binDir);
toc
%% Step04b If binning has been done, load binning parameters
binConfigFileName = 'binConfig.json';
binConfigFilePath = fullfile(binDir,binConfigFileName);
myexp.readBinConfig(binConfigFilePath);
%% Step05 Calculate anatomy maps
anatomyParam.inFileType = 'binned';
anatomyParam.trialOption = [];
myexp.calcAnatomyBatch(anatomyParam);
%% Step06 Align all trials to template
% Do we need this?
%% Save experiment configuration
expFileName = strcat('experimentConfig_',expInfo.name,'.mat');
expFilePath = fullfile(resultDir,expFileName);
save(expFilePath,'myexp')

