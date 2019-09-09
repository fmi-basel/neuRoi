function [commonRoiTagArray,timeTraceMatList,idxMat] = findCommonRoi(traceResultArray)
roiTagArrayList = arrayfun(@getRoiTagArray,traceResultArray, ...
                           'UniformOutput',false);
[commonRoiTagArray,idxMat] = helper.multipleIntersect(roiTagArrayList);

timeTraceMatList = {};
for k=1:length(traceResultArray)
    timeTraceMatList{k} = traceResultArray(k).timeTraceMat(idxMat(k,:),:);
end

function roiTagArray = getRoiTagArray(traceResult)
roiTagArray = arrayfun(@(x) x.tag, traceResult.roiArray);
