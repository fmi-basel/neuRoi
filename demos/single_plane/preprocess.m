%% Add neuRoi root directory to path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Experiment parameters
expInfo.name = 'Nesibe-20190501-f1';
expInfo.frameRate = 30;
expInfo.odorList = {'Ala','Trp','Ser','ACSF','TCA','GCA','TDCA','Spont'};
expInfo.nTrial = 3;
expInfo.nPlane = 1;

expSubDir = expInfo.name;
% Raw data
dataRootDir = '/media/hubo/Bo_FMI/Ca_imaging/';
rawDataDir = fullfile(dataRootDir,'raw_data','Nesibe_2Photon/20190501/f1/');
rawFileList = {'BH0018_35dpf_lOB_91um_o5GCA_001_.tif';...
               'BH0018_35dpf_lOB_91um_o3Ser_001_.tif';...
               'BH0018_35dpf_lOB_91um_o6TDCA_001_.tif';...
               'BH0018_35dpf_lOB_91um_o8Spont_001_.tif';...
               'BH0018_35dpf_lOB_91um_o4TCA_001_.tif';...
               'BH0018_35dpf_lOB_91um_o1Ala_001_.tif';...
               'BH0018_35dpf_lOB_91um_o2Trp_001_.tif';...
               'BH0018_35dpf_lOB_91um_o7ACSF_001_.tif';...
               'BH0018_35dpf_lOB_91um_o8Spont_002_.tif';...
               'BH0018_35dpf_lOB_91um_o3Ser_002_.tif';...
               'BH0018_35dpf_lOB_91um_o5GCA_002_.tif';...
               'BH0018_35dpf_lOB_91um_o6TDCA_002_.tif';...
               'BH0018_35dpf_lOB_91um_o4TCA_002_.tif';...
               'BH0018_35dpf_lOB_91um_o1Ala_002_.tif';...
               'BH0018_35dpf_lOB_91um_o2Trp_002_.tif';...
               'BH0018_35dpf_lOB_91um_o7ACSF_002_.tif';...
               'BH0018_35dpf_lOB_91um_o5GCA_003_.tif';...
               'BH0018_35dpf_lOB_91um_o1Ala_003_.tif';...
               'BH0018_35dpf_lOB_91um_o4TCA_003_.tif';...
               'BH0018_35dpf_lOB_91um_o7ACSF_003_.tif';...
               'BH0018_35dpf_lOB_91um_o8Spont_003_.tif';...
               'BH0018_35dpf_lOB_91um_o2Trp_003_.tif';...
               'BH0018_35dpf_lOB_91um_o3Ser_003_.tif';...
               'BH0018_35dpf_lOB_91um_o6TDCA_003_.tif'};


% Data processing configuration
% Directory for saving processing results
resultRootDir = '/home/hubo/Projects/Ca_imaging/results';
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
%% Step04a Calculate anatomy maps
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
%% Step05a Align trial to template
templateRawName = 'BH0018_35dpf_lOB_91um_o3Ser_002_.tif';
templateNameTail = templateRawName(end-13+1:end-4);
templateRawName = templateRawName;
alignFileName = sprintf('alignResult_template%s.mat',...
                                  templateNameTail);
% plotFig = false;
% climit = [0 0.5];
for planeNum=1:myexp.expInfo.nPlane
    myexp.alignTrialBatch(templateRawName,alignFileName,...
                          'planeNum',planeNum,...
                          'alignOption',{'plotFig',false});
end
%% Step05b Load alignment result
alignDir = myexp.getDefaultDir('alignment');
templateRawName = 'BH0018_35dpf_lOB_91um_o3Ser_002_.tif';
templateNameTail = templateRawName(end-13+1:end);
templateRawName = templateRawName;
alignFileName = sprintf('alignResult_template%s.mat',...
                        templateNameTail);
alignFilePath = fullfile(alignDir,alignFileName);
myexp.loadAlignResult(alignFilePath);
%% Save experiment configuration
expFileName = strcat('experimentConfig_',expInfo.name,'.mat');
expFilePath = fullfile(resultDir,expFileName);
save(expFilePath,'myexp')
