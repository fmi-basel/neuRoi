%% Add path
addpath('..');
%% Clear variables
clear all
close all
%% File paths
dataDir = '/home/hubo/Projects/Ca_imaging/data/2018-07-06-OB3trial';
subDir = '2018-08-15-OBGCmarker/';
fileBaseNameArray={'BH18_30dpf_f6_rOB_55um_sr1_1ala_001_.tif',...
                   'BH18_30dpf_f6_rOB_55um_sr1_2trp_003_.tif'}

filePathArray = cellfun(@(x) fullfile(dataDir,x), ...
                        fileBaseNameArray,'UniformOutput',false);
%% NrMvc
mymodel = NrModel();
mycon = NrController(mymodel);
zrange = [1 200]
mycon.openTrial(filePathArray{1},zrange);
%% Open another trial
mycon.openTrial(filePathArray{2},zrange);
% %% Initialize model
% mymodel = NrModel(filePathArray);
% mymodel.loadMovieOption.zrange = [1 100];
% mymodel.loadMovieOption.nFramePerStep = 2;
% mycontroller = NrController(mymodel);
% % loadMovieOption = struct('startFrame',10,'nFrame',10);
% % mycontroller.setLoadMovieOption(loadMovieOption);
% %% Test current trial
% currentTrialInd = mymodel.currentTrialInd;
% currentTrialController = mycontroller.trialControllerArray{currentTrialInd};
% responseOption = struct('offset',-10,'fZeroWindow',[1 2],'responseWindow',[3,4]);
% currentTrialController.addMap('response',responseOption);
