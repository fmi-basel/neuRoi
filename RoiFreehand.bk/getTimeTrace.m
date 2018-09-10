function [timeTraceRaw,timeTraceDf] = getTimeTrace(rawMovie,roi,varargin)
    % GETTIMETRACE function to get time trace of dF/F within a ROI
    % from the input raw movie
    % Usage: getTimeTrace(rawMovie,roi,[intensityOffset])
    
    if nargin == 2
        intensityOffset = 0;
    elseif nargin == 3
        intensityOffset = varargin{1};
    else
        error('Usage: getTimeTrace(rawMovie,roi,[intensityOffset])')
    end
    
    mask = roi.createMask;
    [maskIndX maskIndY] = find(mask==1);
    roiMovie = rawMovie(maskIndX,maskIndY,:);
    timeTraceRaw = mean(mean(roiMovie,1),2);
    timeTraceRaw =timeTraceRaw(:);

    timeTraceFg = timeTraceRaw - intensityOffset;
    timeTraceSm = smooth(timeTraceFg,10);
    fZero = quantile(timeTraceSm(10:end-10),0.1);
    
    % Time trace of dF/F, unit in percent
    timeTraceDf = (timeTraceSm - fZero) / fZero * 100;
    
