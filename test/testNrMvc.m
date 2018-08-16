%% Add path
addpath('..');
%% Clear variables
clear all
%% File paths
dataDir = '/home/hubo/Projects/Ca_imaging/data/';
subDir = '2018-08-15-OBGCmarker/';
fileBaseNameArray={'BH25_34dpf_OGB_2channel_longOdor_70um_trp_004_',...
                  'BH25_34dpf_OGB_2channel_longOdor_70um_food_004_'};
filePathArray = cellfun(@(x) fullfile(dataDir,subDir,[x '.tif']),fileBaseNameArray,'UniformOutput',false);
%% Initialize model
mymodel = NrModel(filePathArray);
mycontroller = NrController(mymodel);
% loadMovieOption = struct('startFrame',10,'nFrame',10);
% mycontroller.setLoadMovieOption(loadMovieOption);
%% Test current trial
currentTrialInd = mymodel.currentTrialInd;
currentTrialController = mycontroller.TrialControllerArray{ind};
responseOption = struct('offset',-10,'fZeroWindow',[1 2],responseWindow,[3,4])
currentTrialController.addMap('response',responseOption);
