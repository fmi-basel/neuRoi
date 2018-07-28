%% Add path
addpath('..')
addpath('../helpers')
addpath('../movieProcessing')
addpath('../roi')
%% Clear variables
clear all
%% Create an NrModel object
baseDir = '/home/hubo/Projects/Ca_imaging/data/2018-05-24';
fileName='BH18_25dpf_f2_OB_afterDp_food_001_.tif';
filePath = fullfile(baseDir,fileName);

loadMovieOption = struct('startFrame', 50, ...
                         'nFrame', 200);
mymodel = NrModel(filePath,loadMovieOption);

%% Create GUI with controller
mycontroller = NrController(mymodel);
% gg = mycontroller.view.guiHandles.mapBottonGroup;
% gg.SelectedObject;
  
