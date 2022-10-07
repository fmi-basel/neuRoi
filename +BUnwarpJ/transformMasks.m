function masks = transformMasks(templateMask, rawTransformList)
    maskSize = size(templateMask);
    masks=zeros(length(rawTransformList), maskSize(1), maskSize(2));
    for k=1:length(rawTransformList)
        rawTransform = rawTransformList{k};
        outputMask= BUnwarpJ.fcn_ApplyRawTransformation(templateMask, rawTransform);
        masks(k,:,:) = outputMask;
        tempString= strcat(int2str(k), " of ",int2str(length(rawTransformList)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString); 
    end
end
