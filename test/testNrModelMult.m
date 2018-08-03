%% Add path
addpath('..')
%% Clear variables
clear all
%% Initialize model
dataDir = '/home/hubo/Projects/Ca_imaging/data/';
subDir = '2018-07-16-OB3TrialLateral';
fileBaseNameArray={'BH18_32dpf_f1_OB_105um_s1_o3food_001_', ...
                   'BH18_32dpf_f1_OB_105um_s2_o3food_001_', ...
                   'BH18_32dpf_f1_OB_105um_s3_o3food_001_', ...
                  };
filePathArray=cellfun(@(x) fullfile(dataDir,subDir,[x,'.tif']), ...
                      fileBaseNameArray,'UniformOutput',false);
mymodel = NrModel(filePathArray);
%% Load data from file
ind = 2;
trial = mymodel.getTrialByInd(ind);
trial.readDataFromFile();
