function maskImg = convertRoiArrayToMask(roiArray,imageSize)
    maskImg = zeros(imageSize,'uint16');
    for roi=roiArray
        maskImg = min(maskImg + uint16(roi.createMask(imageSize)*roi.tag), uint16(roi.tag));
    end
    
end
