function NewTrialPathArray = claheImages(imageList, param, outDir)
% Load trials
    for k = 1:length(imageList)
        tempImgArray(k,:,:)= imread(imageList{k}); 
        tempString= strcat("Loading trial ",int2str(k));
        disp(tempString);   
    end

    % CLAHE and save image
    NewTrialPathArray = {};
    for k = 1:length(imageList)
        NormImgArray(k,:,:) = adapthisteq(squeeze(tempImgArray(k,:,:)),...
                                        "NumTiles", param.NumTiles,...
                                        'ClipLimit', param.ClipLimit);
        
        NewTrialPathArray{k} = fullfile(outDir, iopath.modifyFileName(imageList{k},...
                                                          '','_Norm', 'tif'));
        imwrite(squeeze(NormImgArray(k,:,:)),NewTrialPathArray{k});
        tempString= strcat("Save hist norm trial ",int2str(k));
        disp(tempString); 
    end

end

