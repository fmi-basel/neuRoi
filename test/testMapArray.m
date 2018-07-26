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

%% Add map
mymodel.calculateAndAddNewMap('anatomy');
responseOption = struct('offset',-10,'fZeroWindow',[10 20],'responseWindow',[50 100]);
mymodel.calculateAndAddNewMap('response',responseOption);

%% Update map
mapOption.nFrameLimit = [1 2];
mymodel.updateMap(1,mapOption);

responseOption = struct('offset',-10,'fZeroWindow',[10 20],'responseWindow',[60 70]);
mymodel.updateMap(2,responseOption);

