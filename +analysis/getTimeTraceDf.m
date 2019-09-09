function timeTraceDf = getTimeTraceDf(timeTrace,param)
% GETTIMETRACEDF calculate dF/F from raw time traces
% timeTrace: can either be a 1xM vector containing single time
% trace, or a NxM matrix containing N traces of length M

dim = 2;
timeTraceFg = timeTrace - param.intensityOffset;
if param.gaussN
    timeTraceSm = helper.gaussFilter1D(timeTraceFg,param.gaussN, ...
                                       param.gaussAlpha,1);
    fZero = quantile(timeTraceSm(param.fZeroWindow),param.fZeroPercent,dim);
    timeTraceDf = (timeTraceSm - fZero) ./ fZero;
else
    fZero = quantile(timeTraceFg(param.fZeroWindow),param.fZeroPercent,dim);
    timeTraceDf = (timeTraceFg - fZero) ./ fZero;
end
