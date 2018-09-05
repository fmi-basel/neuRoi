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
%% Create TrialModel object
filePath = filePathArray{1};
loadMovieOption.zrange = [1 100];
loadMovieOption.nFramePerStep = 2;
trial = TrialModel(filePath,loadMovieOption);
%% Test ROI functions
position = [1 2;3 4];
imageInfo = struct('xdata',[1 2],'ydata',[3,4],'imageSize',[512 ...
                    512]);
trial.addRoi(position,imageInfo);
%% add more roi
trial.addRoi(position,imageInfo);
