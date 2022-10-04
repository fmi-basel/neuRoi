function masks = transformMasks(templateMask, rawTransformList)
    maskSize = size(templateMask);
    masks=zeros(length(rawTransformList), maskSize(1), maskSize(2));
    for i=1:length(rawTransformList)
        rawTransform = rawTransformList{k};
        outputMask= fcn_ApplyRawTransformation(templateMask, rawTransform);
        masks(i,:,:) = outputMask;
        tempString= strcat(int2str(i), " of ",int2str(length(rawTransformList)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString); 
    end
end
