% calculate dFoverF for a response window and for a moving window, taking
% the maximum response for each location
function [DF_response,DF_master,DF_movie] = dFoverF(rawMovie,offset,f0_window,response_window,returnDfMovie)
DF_raw = mean(rawMovie(:,:,response_window(1):response_window(2)),3);   
F0_raw = mean(rawMovie(:,:,f0_window(1):f0_window(2)),3);

F0 = conv2(F0_raw,fspecial('gaussian',[3 3], 1),'same');
DF = (DF_raw - F0)./(F0-offset);
DF_response = conv2(DF,fspecial('gaussian',[3 3], 2),'same');

DF_master = zeros(size(rawMovie(:,:,1)));
sliding_window_size = 50;
for i = 1:floor(size(rawMovie,3)/sliding_window_size)
    DF = mean(rawMovie(:,:,((i-1)*sliding_window_size+1):(min(i*sliding_window_size+1,size(rawMovie,3)))),3);
    DF = (DF - F0)./(F0-offset*1.00);
    DF = conv2(DF,fspecial('gaussian',[3 3], 2),'same');
    DF_master = max(DF_master,DF);
end
 
if returnDfMovie
    F0 = mean(rawMovie(:,:,F0_window),3);
    F0 = conv2(F0,fspecial('gaussian',[3 5], 3),'same');
    DF_movie = (rawMovie - repmat(F0,[1 1 size(rawMovie,3)]))./(repmat(F0,[1 1 size(rawMovie,3)]) - offset);
else
    DF_movie = [];
end
