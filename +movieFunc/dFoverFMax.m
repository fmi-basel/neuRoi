function responseMaxMap = dFoverFMax(rawMovie,offset,fZeroWindow, ...
                                     slidingWindowSize,lowerPercentile, skippingNumber )


% fZeroWindow: 2D array that contains beginning and end frame number of
% the baseline period.
% responseWindow: 2D array that contains beginning and end frame
% number of the responding period.
% lowerPercentile:lower percentile which will be used considered as F0;
% skippingNumber: only every "skippingNumber" frame will be used for the
% calculation-only works if lowerPercentile is used
% window parameter will be ignored if the other input arguments are present

UseWindow=true;

if exist('lowerPercentile','var') && exist('skippingNumber','var')
    UseWindow=false;
else
    UseWindow=true;
end

if UseWindow
    nFrame = size(rawMovie,3);
    nChunk = floor(nFrame/slidingWindowSize);
    nFrameConsidered = nChunk*slidingWindowSize;
    chunkedMovie = reshape(rawMovie(:,:,1:nFrameConsidered), ...
                           [size(rawMovie(:,:,1)),slidingWindowSize,nChunk]);
    chunkedMovieAvg = mean(chunkedMovie,3);
    cmSize = size(chunkedMovieAvg);
    chunkedMovieAvg = reshape(chunkedMovieAvg,[cmSize(1:2),cmSize(4)]);
    

    fZeroGaussianHsize = 5;%3
    fZeroGaussianSigma = 1;%1

    dfGaussianHsize = 5;%3
    dfGaussianSigma = 1.5;%2
    fZeroRaw = mean(rawMovie(:,:,fZeroWindow(1):fZeroWindow(2)),3);
    fZero = conv2(fZeroRaw,fspecial('gaussian',[fZeroGaussianHsize, fZeroGaussianHsize], fZeroGaussianSigma),'same');
    
    dfOvrFRaw = (chunkedMovieAvg - fZero)./(fZero - offset);
    dfOvrFRaw = mat2cell(dfOvrFRaw,cmSize(1),cmSize(2),ones(1,cmSize(4)));
    dfOvrF = cellfun(@(x) conv2(x,fspecial('gaussian',[dfGaussianHsize dfGaussianHsize], dfGaussianSigma), ...
                                'same'),dfOvrFRaw,'UniformOutput', false);
    dfOvrF = cell2mat(dfOvrF);
    
    responseMaxMap = max(abs(dfOvrF),[],3);

else
    if skippingNumber>0
        chunkedMovie=rawMovie(:,:,1:skippingNumber:end);
    else
        chunkedMovie=rawMovie;
    end

    nFrame = size(rawMovie,3);%30600
    nChunk = floor(nFrame/slidingWindowSize);
    nFrameConsidered = nChunk*slidingWindowSize;
    chunkedMovie = reshape(rawMovie(:,:,1:nFrameConsidered), ...
                           [size(rawMovie(:,:,1)),slidingWindowSize,nChunk]); %256*512*50*612

    chunkedMovieAvg = mean(chunkedMovie,3); %256*512*1*612
    cmSize = size(chunkedMovieAvg); %256*512*1*612
    chunkedMovieAvg = reshape(chunkedMovieAvg,[cmSize(1:2),cmSize(4)]);%256*512*612
    
    fZeroRawPercentile = prctile(chunkedMovieAvg,lowerPercentile,3); %256*512
    fZeroRaw=double(chunkedMovieAvg);
    fZeroRaw(fZeroRaw> fZeroRawPercentile)=NaN;
    fZeroRaw =mean(fZeroRaw,3,"omitnan");
    fZero = conv2(fZeroRaw,fspecial('gaussian',[3 3], 1),'same');%256*512
    
    dfOvrFRaw = (chunkedMovieAvg - fZero)./(fZero - offset);%256*512*612
    dfOvrFRaw = mat2cell(dfOvrFRaw,cmSize(1),cmSize(2),ones(1,cmSize(4)));%1*1*612
    dfOvrF = cellfun(@(x) conv2(x,fspecial('gaussian',[3 3], 2), ...
                                'same'),dfOvrFRaw,'UniformOutput', false);
    dfOvrF = cell2mat(dfOvrF);%256*512*612
    
    responseMaxMap = max(abs(dfOvrF),[],3);

end
