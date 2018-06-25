function responseMap = dFoverF(rawMovie,offset,fzeroWindow,responseWindow)
dfRaw = mean(rawMovie(:,:,responseWindow(1):responseWindow(2)),3);   
fZeroRaw = mean(rawMovie(:,:,fzeroWindow(1):fzeroWindow(2)),3);

fZero = conv2(fZeroRaw,fspecial('gaussian',[3 3], 1),'same');
df = (dfRaw - fZero)./(fZero-offset);
responseMap = conv2(df,fspecial('gaussian',[3 3], 2),'same');
