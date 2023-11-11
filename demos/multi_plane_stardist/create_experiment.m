addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Load 
% Experiment parameters
expInfo.name = '2021-07-31-DpOBEM-JH17';
expInfo.frameRate = 30;
expInfo.odorList = {'phe','trp','arg','tca','gca','tdca','acsf','spont'};
expInfo.nTrial = 3;
expInfo.nPlane = 4;
% TODO delete this line and set this to false by default expInfo.planeDoubling = false;


rootPaths = load('../../../paths/rootPaths.mat');

expSubDir = fullfile(expInfo.name,'Dp');
dataRootDir = fullfile(rootPaths.tungstenCaData, 'raw_data');
rawDataDir = fullfile(dataRootDir,expSubDir);

% List file command ls -1|awk '{print "\x27" $1 "\x27;..."}'

% rawFileList = dir(fullfile(rawDataDir, ...
%                            '*_JH*_*_s*_o*.tif'));
rawFileList = dir(fullfile(rawDataDir, ...
                           '*_*_s*_o*.tif'));
rawFileList = arrayfun(@(x) x.name, rawFileList,'UniformOutput',false);
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*reference.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*alignment.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'SUM.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*_s0_.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*_raw.*');
rawFileList = rawFileList(1:3);

% Data processing configuration
% Directory for saving processing results
resultRootDir = fullfile(rootPaths.tungstenCaData, 'results_tmp');
resultDir = fullfile(resultRootDir,expSubDir);
% Directory for saving binned movies
binDir = fullfile(dataRootDir, 'binned_movie', expSubDir);

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
templateIdx = 12;
% Start preprocessing
myexp.processRawData('subtractScan',true,...
                     'noSignalWindow', [1 4],...
                     'mcWithinTrial',false,...
                     'mcBetweenTrial',false,...
                     'mcBTTemplateIdx',templateIdx,...
                     'binning',false);

%  Save experiment configuration
filePath = myexp.getDefaultFile('experiment');
myexp.saveExperiment(filePath);
