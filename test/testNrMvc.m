%% Add path
addpath('..');
%% Clear variables
clear all
close all
%% File paths
dataDir = '/home/hubo/Projects/Ca_imaging/data/';
subDir = '2018-08-15-OBGCmarker/';
fileBaseNameArray={'BH25_34dpf_OGB_2channel_longOdor_70um_trp_004_',...
                  'BH25_34dpf_OGB_2channel_longOdor_70um_food_004_'};
filePathArray = cellfun(@(x) fullfile(dataDir,subDir,[x '.tif']), ...
                        fileBaseNameArray,'UniformOutput',false);
%% NrMvc
mymodel = NrModel();
mycon = NrController(mymodel);
mycon.openTrial(filePathArray{1});
%% Open another trial
mycon.openTrial(filePathArray{2});
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
