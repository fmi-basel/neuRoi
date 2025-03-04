function responseMap = dFoverF(rawMovie,offset,fzeroWindow, ...
                               responseWindow,lowerPercentile, skippingNumber,averagedData, substractMinimum )
% DFOVERF calculates the map of change of fluorescence (dF/F) of a
% calcium imaging movie in a given response window
% Usage: 
% responseMap = dFoverF(rawMovie,offset,fzeroWindow,responseWindow,lowerPercentile, skippingNumber)
% rawMovie: the 3D array that contains the calcium imaging data
% offset: the value where no signal is acquired. This is usually
% the median intensity value in the frames before PMT signal comes
% in, or can be customized by user. Note that the offset should
% leave a security distance, so that fZero is not too close to
% zero. 
% fZeroWindow: 2D array that contains beginning and end frame number of
% the baseline period.
% responseWindow: 2D array that contains beginning and end frame
% number of the responding period.
% lowerPercentile:lower percentile which will be used considered as F0;
% skippingNumber: only every "skippingNumber" frame will be used for the
% calculation-only works if lowerPercentile is used
% window parameter will be ignored if the other input arguments are present

%JE: modified to work without windows but rather with lower percentiles as 
%F0 and add the skipping parameter for long reordings-for setupC

UseWindow=true;

if exist('lowerPercentile','var') && exist('skippingNumber','var')
    UseWindow=false;
else
    UseWindow=true;
end

if exist('averagedData','var') && ~isempty(averagedData)
    precalcuatedAverage=true;
else
    precalcuatedAverage=false;
end

if exist('substractMinimum','var') && ~isempty(substractMinimum)
    
else
    substractMinimum=false;
end


if UseWindow
    dfRaw = mean(rawMovie(:,:,responseWindow(1):responseWindow(2)),3);
    % dfRaw = max(rawMovie(:,:,responseWindow(1):responseWindow(2)),[], 3);
    dfRaw = double(dfRaw);
    fZeroRaw = mean(rawMovie(:,:,fzeroWindow(1):fzeroWindow(2)),3);
    
    fZeroGaussianHsize = 5;%3
    fZeroGaussianSigma = 1;%1
    fZero = conv2(fZeroRaw,fspecial('gaussian',[fZeroGaussianHsize, fZeroGaussianHsize], fZeroGaussianSigma),'same');
    df = (dfRaw - fZero)./(fZero-offset);
    dfGaussianHsize = 5;%3
    dfGaussianSigma = 1.5;%2
    responseMap = conv2(df,fspecial('gaussian',[dfGaussianHsize dfGaussianHsize], dfGaussianSigma),'same');

else
   

    if skippingNumber>0
        subRawMovie=rawMovie(:,:,1:skippingNumber:end);
    else
        subRawMovie=rawMovie;
    end
    if precalcuatedAverage
        dfRaw = averagedData;
    else
        dfRaw = mean(subRawMovie,3);
    end
   

    fZeroRawPercentile=prctile(subRawMovie,lowerPercentile,3);
    fZeroRaw=double(subRawMovie);
    fZeroRaw(fZeroRaw> fZeroRawPercentile)=NaN;
    fZeroRaw =mean(fZeroRaw,3,"omitnan");
    
     if substractMinimum
        stackMin=min(rawMovie,[],3);
        stackMin=double(stackMin);
        fZeroRaw=fZeroRaw-stackMin;
        dfRaw=dfRaw-stackMin;
    end

    fZero = conv2(fZeroRaw,fspecial('gaussian',[3 3], 1),'same');
    df = (dfRaw - fZero)./(fZero-offset);
    responseMap = conv2(df,fspecial('gaussian',[3 3], 2),'same');
end
