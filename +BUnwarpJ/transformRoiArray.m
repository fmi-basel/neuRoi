function roiArrayStack = transformRoiArray(templateRoiArr, transform)
    roiMap = templateRoiArray.convertToMask();
    outputMask= BUnwarpJ.applyTransformation(roiMap, transform);
    roiArr = roiFunc.RoiArray('maskImg',outputMask);
    % TODO handle the situation when a subset of ROIs are not transformed successfully
end
