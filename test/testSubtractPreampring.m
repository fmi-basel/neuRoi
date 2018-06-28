baseDir = '/home/hubo/Projects/Ca_imaging/data/2018-05-24';
fileName='BH18_25dpf_f2_OB_afterDp_food_001_.tif';
filePath = fullfile(baseDir,fileName);

movieMeta = readMeta(filePath);
rawMovie = readMovie(filePath,movieMeta);

noSignalWindow = [1 12];
[subMovie,templ] = subtractPreampRing(rawMovie,noSignalWindow);

%% Show template
imagesc(templ)

%% Show averaged movies
rawMovieAvg = mean(rawMovie,3);
subMovieAvg = mean(subMovie,3);
figure()
imagesc(rawMovieAvg)
figure()
imagesc(subMovieAvg)



