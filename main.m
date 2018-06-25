function [mymodel,mycontroller] = main()
baseDir = '/home/hubo/Projects/Ca_imaging/data/2018-05-24';
fileName='BH18_25dpf_f2_OB_afterDp_food_001_.tif';
filePath = fullfile(baseDir,fileName);

mymodel = NrModel(filePath);
mycontroller = NrController(mymodel);

