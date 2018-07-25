baseDir = '/home/hubo/Projects/Ca_imaging/data/2018-02-07';
fileName='BH18_19dpf_f3_rightOB_pos3_food_004_.tif';
filePath = fullfile(baseDir, fileName);

tmodel= NrModel(filePath);

img = imagesc(tmodel.anatomyMap)

roi1 = imfreehand
roi1pos = roi1.getPosition()
roi1Mask = roi1.createMask;
[maskIndX maskIndY] = find(mask==1)

