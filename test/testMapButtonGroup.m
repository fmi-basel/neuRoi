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
                         'nFrame', 100);
mymodel = NrModel(filePath,loadMovieOption);
%% Calculate maps
mymodel.calculateAndAddNewMap('anatomy');
mymodel.calculateAndAddNewMap('response');

%% Calculate real maps
responseOption=struct('offset',-10,...
                      'fZeroWindow',[100 200],...
                      'responseWindow',[400 600]);
mymodel.calculateAndAddNewMap('response',responseOption);
responseMaxOption=struct('offset',-10,...
                         'fZeroWindow',[100 200],...
                         'slidingWindowSize',100);
mymodel.calculateAndAddNewMap('responseMax',responseMaxOption);

%% Create GUI with controller
mycontroller = NrController(mymodel);
% gg = mycontroller.view.guiHandles.mapBottonGroup;
% gg.SelectedObject;
  
% %% Test dFoverFMax
% rawMovie = mymodel.rawMovie;
% offset = -10;
% fZeroWindow = [3 5];
% slidingWindowSize = 10;
% responseMaxMap = dFoverFMax(rawMovie,offset,fZeroWindow, ...
%                                      slidingWindowSize);
%% Add map
mycontroller.addMap('anatomy');
%% Delete map
mycontroller.deleteCurrentMap();
 
