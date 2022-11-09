function act_map = calc_act_mapSetupC(rawMovie, meanWindow, gaussianBlur )

    if exist('meanWindow','var') && ~isempty(meanWindow) && (meanWindow>0)
        useMeanWindow=true;
    else
        useMeanWindow=false;
    end


    if useMeanWindow
        nFrame = size(rawMovie,3);
        nChunk = floor(nFrame/meanWindow);
        nFrameConsidered = nChunk*meanWindow;
        chunkedMovie = reshape(rawMovie(:,:,1:nFrameConsidered), ...
                               [size(rawMovie(:,:,1)),meanWindow,nChunk]); 
        rawMovie = mean(chunkedMovie,3);
        cmSize = size(rawMovie); 
        rawMovie = reshape(rawMovie,[cmSize(1:2),cmSize(4)]);
    end
    
    rawMovie = rawMovie - double(min(rawMovie(:)));
    act_map = double(max(rawMovie,[],3)) ./ (mean(rawMovie,3) + 200);

    if gaussianBlur
        act_map = conv2(act_map,fspecial('gaussian',[3 3], 2),'same');    
    end

end