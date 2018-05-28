function timeTrace = getTimeTrace(rawMovie,roi)
 mask = roi.createMask;
 [maskIndX maskIndY] = find(mask==1);
 roiMovie = rawMovie(maskIndX,maskIndY,:);
 timeTrace = mean(mean(roiMovie,1),2);
 timeTrace =timeTrace(:);
 
