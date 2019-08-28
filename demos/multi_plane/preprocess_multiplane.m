%% Add neuRoi rood directory to path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Load 
% Experiment parameters
expInfo.name = '2019-08-25-fastZ2';
expInfo.frameRate = 30;
expInfo.odorList = {'ala','trp','ser','acsf','tca','gca','tdca','spont'};
expInfo.nTrial = 2;
expInfo.nPlane = 4;


rootPaths = load('../../../paths/rootPaths.mat');

expSubDir = expInfo.name;
% Raw data
dataRootDir = fullfile(rootPaths.extHardDisk,'Ca_imaging');
rawDataDir = fullfile(dataRootDir,'raw_data','2019-08-25-fastZ2');
% List file command ls -1|awk '{print "\x27" $1 "\x27;..."}'
rawFileList = {'20190825_BH18_37dpf_OB_fastz_s1_o1tdca_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s1_o2trp_003_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s1_o3gca_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s1_o4ala_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s1_o5ser_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s1_o6tca_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s1_o7acsf_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o1ala_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o2tca_redo_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o3gca_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o4trp_002_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o5ser_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o6tdca_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s2_o7acsf_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s3_o1spont_001_.tif';...
               '20190825_BH18_37dpf_OB_fastz_s3_o1spont_002_.tif'};


% Data processing configuration
% Directory for saving processing results
resultRootDir = fullfile(rootPaths.projectDir,'results');
resultDir = fullfile(resultRootDir,expSubDir);
% Directory for saving binned movies
binDir = fullfile(dataRootDir,'binned_movie',expSubDir);

%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel(rawDataDir,rawFileList,resultDir,...
                expInfo);
%% Step03a (optional) Bin movies
% Bin movie parameters
binParam.shrinkFactors = [1, 1, 2];
binParam.trialOption = struct('process',true,'noSignalWindow',[1 4]);
binParam.depth = 8;
for planeNum=1:myexp.expInfo.nPlane
myexp.binMovieBatch(binParam,binDir,planeNum);
end
%% Step03b (optional) If binning has been done, load binning
%% parameters to experiment
%read from the binConfig file to get the binning parameters
binConfigFileName = 'binConfig.json';
binConfigFilePath = fullfile(binDir,binConfigFileName);
myexp.readBinConfig(binConfigFilePath);
%% Step04 Calculate anatomy maps
% anatomyParam.inFileType = 'raw';
% anatomyParam.trialOption = {'process',true,'noSignalWindow',[1 12]};
anatomyParam.inFileType = 'binned';
anatomyParam.trialOption = [];
for planeNum=1:myexp.expInfo.nPlane
    myexp.calcAnatomyBatch(anatomyParam,planeNum);
end
%% Step04b If anatomy map has been calculated, load anatomy
%% parameters to experiment
anatomyDir = myexp.getDefaultDir('anatomy');
anatomyConfigFileName = 'anatomyConfig.json';
anatomyConfigFilePath = fullfile(anatomyDir,anatomyConfigFileName);
myexp.readAnatomyConfig(anatomyConfigFilePath);
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
