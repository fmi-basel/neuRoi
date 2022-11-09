addpath('../')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Load 
% Experiment parameters
expInfo.name = 'test-data';
expInfo.frameRate = 30;
expInfo.odorList = {'ala','trp','ser','acsf','tca','gca','tdca','spont'};
expInfo.nTrial = 3;
expInfo.nPlane = 4;


% rootPaths = load('../../../paths/rootPaths.mat');

% expSubDir = fullfile(expInfo.name,'OB');
% % Raw data
% dataRootDir = fullfile(rootPaths.extHardDisk,'Ca_imaging');
rawDataDir = '../raw_data/test-data/';

% List file command ls -1|awk '{print "\x27" $1 "\x27;..."}'

rawFileList = dir(fullfile(rawDataDir, ...
                           '20191218_NT07aTGC6s_dof1112_OB_fastz_s*.tif'));
rawFileList = arrayfun(@(x) x.name, rawFileList,'UniformOutput',false);
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*reference.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*alignment.*');


% Data processing configuration
% Directory for saving processing results
resultDir = fullfile(rawDataDir,'results');
% Directory for saving binned movies
binDir = fullfile(rawDataDir,'binned_movie');

%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel('rawDataDir',rawDataDir,...
                'rawFileList',rawFileList,...
                'resultDir',resultDir,...
                'expInfo',expInfo);
%% Preprocessing
% Bin movie parameters
binParam.shrinkFactors = [1, 1, 2];
binParam.trialOption = struct('process',true,'noSignalWindow',[1 4]);
binParam.depth = 8;
% Start preprocessing
myexp.processRawData('subtractScan',true,...
               'noSignalWindow', [1 4],...
               'mcWithinTrial',false,...
               'mcBetweenTrial',true,...
               'binning',true,...
               'binDir',binDir,...
               'binParam',binParam);

%% Save experiment configuration
filePath = myexp.getDefaultFile('experiment');
myexp.saveExperiment(filePath);
