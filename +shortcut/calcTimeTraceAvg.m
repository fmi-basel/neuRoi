function [timeTraceAvgArray,varargout] = calcTimeTraceAvg(timeTraceMatArray,nTrialPerOdor)
timeTraceAvgArray = {};
timeTraceSemArray = {};
for k=1:nTrialPerOdor:length(timeTraceMatArray)
    concatTimeTraceMat = cell2mat(...
        timeTraceMatArray(k:k+nTrialPerOdor-1)');
    odorInd = ceil(k/nTrialPerOdor);
    timeTraceAvgArray{odorInd} = mean(concatTimeTraceMat,1);
    timeTraceSemArray{odorInd} = std(concatTimeTraceMat,1)/ ...
                               sqrt(size(concatTimeTraceMat,1));
end
if nargout == 2
    varargout{1} = timeTraceSemArray;
end
