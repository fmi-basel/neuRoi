function responseMaxMap = dFoverFMax(rawMovie,offset,fZeroWindow, ...
                                     slidingWindowSize)
nFrame = size(rawMovie,3);
nChunk = floor(nFrame/slidingWindowSize);
nFrameConsidered = nChunk*slidingWindowSize;
chunkedMovie = reshape(rawMovie(:,:,1:nFrameConsidered), ...
                       [size(rawMovie(:,:,1)),slidingWindowSize,nChunk]);
chunkedMovieAvg = mean(chunkedMovie,3);
cmSize = size(chunkedMovieAvg);
chunkedMovieAvg = reshape(chunkedMovieAvg,[cmSize(1:2),cmSize(4)]);

fZeroRaw = mean(rawMovie(:,:,fZeroWindow(1):fZeroWindow(2)),3);
fZero = conv2(fZeroRaw,fspecial('gaussian',[3 3], 1),'same');

dfOvrFRaw = (chunkedMovieAvg - fZero)./(fZero - offset);
dfOvrFRaw = mat2cell(dfOvrFRaw,cmSize(1),cmSize(2),ones(1,cmSize(4)));
dfOvrF = cellfun(@(x) conv2(x,fspecial('gaussian',[3 3], 2), ...
                            'same'),dfOvrFRaw,'UniformOutput', false);
dfOvrF = cell2mat(dfOvrF);

responseMaxMap = max(dfOvrF,[],3);


