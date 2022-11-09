function traceResult = removePointRoi(traceResult)
% Delete ROIs with only one point
roiArray = traceResult.roiArray;
keepIdx = arrayfun(@(x) size(x.position,1)>2, roiArray);
traceResult.timeTraceMat = traceResult.timeTraceMat(keepIdx,:);
traceResult.roiArray = traceResult.roiArray(keepIdx);
