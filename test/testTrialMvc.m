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
loadMovieOption.zrange = [1 100];
loadMovieOption.nFramePerStep = 2;
trial = TrialModel(filePath,loadMovieOption);
trcon = TrialController(trial);
