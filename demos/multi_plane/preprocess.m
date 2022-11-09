addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Load 
% Experiment parameters
expInfo.name = '2020-01-15-longPulse';
expInfo.frameRate = 30;
expInfo.odorList = {'ala','trp','ser','tca','gca','tdca','acsf','spont'};
expInfo.nTrial = 3;
expInfo.nPlane = 4;


rootPaths = load('../../../paths/rootPaths.mat');

expSubDir = fullfile(expInfo.name,'OB');
% Raw data
dataRootDir = fullfile(rootPaths.extHardDisk,'Ca_imaging');
rawDataDir = fullfile(dataRootDir,'raw_data',expSubDir);
% List file command ls -1|awk '{print "\x27" $1 "\x27;..."}'

rawFileList = dir(fullfile(rawDataDir, ...
                           '20200115_BH18aTGC6s_dof191210_OB_fastz8_s*.tif'));
rawFileList = arrayfun(@(x) x.name, rawFileList,'UniformOutput',false);
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*reference.*');
rawFileList = helper.deleteFileNameByPattern(rawFileList,'.*alignment.*');


% Data processing configuration
% Directory for saving processing results
resultRootDir = fullfile(rootPaths.projectDir,'results');
resultDir = fullfile(resultRootDir,expSubDir);
% Directory for saving binned movies
binDir = fullfile(dataRootDir,'binned_movie',expSubDir);

%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel(rawDataDir,rawFileList,resultDir,...
                expInfo);
%% Step03 (optional) Bin movies
% Bin movie parameters
binParam.shrinkFactors = [1, 1, 2];
binParam.trialOption = struct('process',true,'noSignalWindow',[1 4]);
binParam.depth = 8;
for planeNum=1:myexp.expInfo.nPlane
myexp.binMovieBatch(binParam,binDir,planeNum);
end
%% Step04 Calculate anatomy maps
% anatomyParam.inFileType = 'raw';
% anatomyParam.trialOption = {'process',true,'noSignalWindow',[1 12]};
anatomyParam.inFileType = 'binned';
anatomyParam.trialOption = [];
for planeNum=1:myexp.expInfo.nPlane
    myexp.calcAnatomyBatch(anatomyParam,planeNum);
end
%% Step05 Align trial to template
templateRawName = myexp.rawFileList{1};
% plotFig = false;
% climit = [0 0.5];
for planeNum=1:myexp.expInfo.nPlane
    myexp.alignTrialBatch(templateRawName,...
                          'planeNum',planeNum,...
                          'alignOption',{'plotFig',false});
end
%% Save experiment configuration
expFileName = strcat('experimentConfig_',expInfo.name,'.mat');
expFilePath = fullfile(resultDir,expFileName);
save(expFilePath,'myexp')
