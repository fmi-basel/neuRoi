%% Add neuRoi to MATLAB path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Experiment parameters
expInfo.name = '2021-09-02-DpOBEM-JH18';
expInfo.frameRate = 30;
expInfo.odorList = {'phe','trp','arg','tca','gca','tdca','acsf','spont'};
expInfo.nTrial = 3;
expInfo.nPlane = 4;

% Root directory where all experiments are stored
rootPaths = load('../../../paths/rootPaths.mat'); % this file should be changed for different computers of simply change the path variable here
dataRootDir = fullfile(rootPaths.extHardDisk,'BCE', 'Ca_imaging');

% Directory where raw data of this experiment is stored
expSubDir = fullfile(expInfo.name,'OB');
rawDataDir = fullfile(dataRootDir,expSubDir);

% Get the raw data files, filter out files not needed
rawFileList = dir(fullfile(rawDataDir, ...
                           '*_JH*_*_s*_o*.tif'));
rawFileList = arrayfun(@(x) x.name, rawFileList,'UniformOutput',false);
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*reference.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*alignment.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'SUM.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*_s0_.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*_raw.*');

% Directory for saving processing results
resultRootDir = fullfile(rootPaths.projectDir,'results');
resultDir = fullfile(resultRootDir,expSubDir);

%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel('rawDataDir',rawDataDir,...
                'rawFileList',rawFileList,...
                'resultDir',resultDir,...
                'expInfo',expInfo);
%% Step03 Preprocessing
templateIdx = 12;
% Start preprocessing
% This function computes anatomy maps for each trial and plane, and does motion correction if requied.
myexp.processRawData('subtractScan',true,...
                     'noSignalWindow', [1 4],...
                     'mcWithinTrial',false,...
                     'mcBetweenTrial',true,...
                     'mcBTTemplateIdx',templateIdx,...
                     'binning',false);

% Parameter description:
% subtractScan (bool): if true, subtract resonance scan pattern from all frames (used for setup A data). The subtracted movie are not saved, but is used for computing the anatomy maps
% noSignalWindow (2d vector, int): start and end frame of where the resonance scan pattern is computed. Used when subtractScan is true.
% mcWithinTrial (bool): if true, do motion correction within each trial.
% mcBetweenTrial (bool): if true, do alignment between trials.
% mcBTTemplateIdx (int): The index of the file (within the rawFileList) as the alignment template .
% binning (bool): if true, do subsampling of the data and save the binned copy. Then binning parameters should be supplied, for exaple as follows
%               binParam.shrinkFactors = [1, 1, 2];
%               binParam.trialOption = struct('process',true,'noSignalWindow',[1 4]);
%               binParam.depth = 8;

%  Save experiment configuration
filePath = myexp.getDefaultFile('experiment');
myexp.saveExperiment(filePath);
