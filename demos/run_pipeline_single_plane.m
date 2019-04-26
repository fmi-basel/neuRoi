%% Add neuRoi rood directory to path
addpath('../')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Experiment parameters
expInfo.name = '2019-03-15-OBDp';
expInfo.frameRate = 30;
expInfo.odorList = {'ala','trp','ser','acsf'};
expInfo.nTrial = 3;

expSubDir = expInfo.name;
% Raw data
dataRootDir = '/media/hubo/Bo_FMI/Ca_imaging/';
rawDataDir = fullfile(dataRootDir,'raw_data',expSubDir);
rawFileList = {'20190315_BH18_29dfp_Dp_z80um_s1_o1ala_001_.tif',...
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

% Data processing configuration
% Directory for saving processing results
resultRootDir = '/home/hubo/Projects/Ca_imaging/results';
resultDir = fullfile(resultRootDir,expSubDir);
% Directory for saving binned movies
binDir = fullfile(dataRootDir,'binned_movie',expSubDir);

% Anatomy map parameters
%anatomyDir = fullfile(resultDir,'anatomy_map');
anatomyParam.inFileType = 'binned'; % can be 'raw' or 'binned'

% Trial-by-trial alignment parameters
%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel(rawDataDir,rawFileList,resultDir,...
                expInfo);
%% Step03a (optional) Bin movies
% Bin movie parameters
binParam.shrinkFactors = [1, 1, 5];
binParam.trialOption = {'process',true,'noSignalWindow',[1 12]};
binParam.depth = 8;
myexp.binMovieBatch(binParam,binDir,1:2);
%% Step03b (optional) If binning has been done, load binning
%% parameters to NrModel
%read from the binConfig file to get the binning parameters
binConfigFileName = 'binConfig-2019-04-26-14h-12m-20s.json';
binConfigFilePath = fullfile(binDir,binConfigFileName);
myexp.readBinConfig(binConfigFilePath);
%% Step04a Calculate anatomy maps
% anatomyParam.inFileType = 'raw';
% anatomyParam.trialOption = {'process',true,'noSignalWindow',[1 12]};
anatomyParam.inFileType = 'binned';
anatomyParam.trialOption = {};
myexp.calcAnatomyBatch(anatomyParam,1:2);
%% Step04b If anatomy map has been calculated, load anatomy
%% parameters to NrModel
anatomyDir = myexp.getDefaultDir('anatomy');
anatomyConfigFileName = 'anatomyConfig.json';
anatomyConfigFilePath = fullfile(anatomyDir,anatomyConfigFileName);
myexp.readAnatomyConfig(anatomyConfigFilePath);
%% Step05 Align trial to template
templateRawName = '20190315_BH18_29dfp_Dp_z80um_s1_o1ala_001_.tif';
templateNameTail = templateRawName(end-13+1:end);
alignParam.templateRawName = templateRawName;
alignParam.outFileName = sprintf('alignResult_amino_acid_template%s.mat',...
                                  templateNameTail);
myexp.alignTrialBatch(alignParam.templateRawName,alignParam.outFileName,1:2);
