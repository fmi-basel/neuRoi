function timeTraceDf = getTimeTraceDf(timeTrace,param)
% GETTIMETRACEDF calculate dF/F from raw time traces
% timeTrace: a NxM matrix containing N traces of length M

timeTraceFg = timeTrace - param.intensityOffset;
if param.gaussN
    timeTraceSm = helper.gaussFilter1D(timeTraceFg,param.gaussN, ...
                                       param.gaussAlpha,2);
    fZero = quantile(timeTraceSm(:,param.fZeroWindow),param.fZeroPercent,2);
    timeTraceDf = (timeTraceSm - fZero) ./ fZero;
else
    fZero = quantile(timeTraceFg(:,param.fZeroWindow),param.fZeroPercent,2);
    timeTraceDf = (timeTraceFg - fZero) ./ fZero;
end
