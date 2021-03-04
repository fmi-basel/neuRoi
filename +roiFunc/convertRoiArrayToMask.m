function maskImg = convertRoiArrayToMask(roiArray)
    maskImg = zeros(roiArray(1).imageSize);
    for roi=roiArray
        maskImg = maskImg + roi.createMask()*roi.tag;
    end
    
end

