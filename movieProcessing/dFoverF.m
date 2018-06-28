function responseMap = dFoverF(rawMovie,offset,fzeroWindow, ...
                               responseWindow)
% DFOVERF calculates the map of change of fluorescence (dF/F) of a
% calcium imaging movie in a given response window
% Usage: 
% responseMap = dFoverF(rawMovie,offset,fzeroWindow,responseWindow)
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

dfRaw = mean(rawMovie(:,:,responseWindow(1):responseWindow(2)),3);   
fZeroRaw = mean(rawMovie(:,:,fzeroWindow(1):fzeroWindow(2)),3);

fZero = conv2(fZeroRaw,fspecial('gaussian',[3 3], 1),'same');
df = (dfRaw - fZero)./(fZero-offset);
responseMap = conv2(df,fspecial('gaussian',[3 3], 2),'same');
