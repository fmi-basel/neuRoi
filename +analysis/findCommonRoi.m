function [commonRoiTagArray,timeTraceMatList,idxMat] = ...
    findCommonRoi(traceResultArray, varargin)
pa = inputParser;
addParameter(pa,'removePointRoi',false);
parse(pa,varargin{:})
pr = pa.Results;

if pr.removePointRoi
    traceResultArray(1) = analysis.removePointRoi(traceResultArray(1));
end

roiTagArrayList = arrayfun(@getRoiTagArray,traceResultArray, ...
                           'UniformOutput',false);
[commonRoiTagArray,idxMat] = ...
    helper.multipleIntersect(roiTagArrayList);

timeTraceMatList = {};
for k=1:length(traceResultArray)
    timeTraceMatList{k} = traceResultArray(k).timeTraceMat(idxMat(k,:),:);
end

function roiTagArray = getRoiTagArray(traceResult)
roiTagArray = arrayfun(@(x) x.tag, traceResult.roiArray);
