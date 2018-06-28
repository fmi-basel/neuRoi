function [timeTraceRaw,timeTraceDf] = getTimeTrace(rawMovie,roi,varargin)
    % GETTIMETRACE function to get time trace of dF/F within a ROI
    % from the input raw movie
    % Usage: getTimeTrace(rawMovie,roi,[offset])
    
    if nargin == 2
        offset = 0;
    elseif nargin == 3
        offset = varargin{1};
    else
        error('Wrong usage!')
    end
    
    mask = roi.createMask;
    [maskIndX maskIndY] = find(mask==1);
    roiMovie = rawMovie(maskIndX,maskIndY,:);
    timeTraceRaw = mean(mean(roiMovie,1),2);
    timeTraceRaw =timeTraceRaw(:);

    timeTraceFg = timeTraceRaw - offset;
    timeTraceSm = smooth(timeTraceFg,10);
    fZero = min(timeTraceSm(10:end-10));
    
    % Time trace of dF/F, unit in percent
    timeTraceDf = (timeTraceSm - fZero) / fZero * 100;
    
