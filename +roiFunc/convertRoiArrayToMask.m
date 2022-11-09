function maskImg = convertRoiArrayToMask(roiArray,imageSize)
    maskImg = zeros(imageSize);
    for roi=roiArray
        maskImg = min(maskImg + roi.createMask(imageSize)*roi.tag, roi.tag);
    end
    
end

