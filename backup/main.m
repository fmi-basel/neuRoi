function [mymodel,mycontroller] = main()
baseDir = '/home/hubo/Projects/Ca_imaging/data/2018-05-24';
fileName='BH18_25dpf_f2_OB_afterDp_food_001_.tif';
filePath = fullfile(baseDir,fileName);

loadMovieOption = struct('startFrame', 50, ...
                         'nFrame', 200);
responseOption = struct('offset',-10,...
                        'fZeroWindow',[10,20],...
                        'responseWindow',[50,100]);


mymodel = NrModel(filePath,loadMovieOption);
mymodel.responseOption = responseOption;
mycontroller = NrController(mymodel);

