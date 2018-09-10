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
%% Initiate TrialModel
filePath = filePathArray{1};
loadMovieOption.zrange = [1 100] %[101 2000];
loadMovieOption.nFramePerStep = 2;
trial = TrialModel(filePath,loadMovieOption);
trcon = TrialController(trial);
trial.syncTimeTrace = true;
trial.intensityOffset = -10;
%% anatomy map
trcon.addMap('anatomy')
%% response map
responseOption = struct('offset',-10,'fZeroWindow',[100 200], ...
                        'responseWindow',[300 500]);
trcon.addMap('response',responseOption);
%% max response map
responseMaxOption = struct('offset',-10,'fZeroWindow',[100 200], ...
                        'slidingWindowSize',100);
trcon.addMap('responseMax',responseMaxOption);
