function main()
baseDir = '/home/hubo/Projects/juvenile_Ca_imaging/data/2018-05-24';
fileName='BH18_25dpf_f2_tel_long_food_002_.tif';
filePath = fullfile(baseDir,fileName);

mymodel = NrModel(filePath);
mycontroller = NrController(mymodel);

