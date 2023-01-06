function troiArr = transformRoiArray(roiArr, transform, offsetYx)
    roiMap = roiArr.convertToMask();
    outputMask= Bunwarpj.applyTransformation(roiMap, transform, offsetYx);
    troiArr = roiFunc.RoiArray('maskImg',outputMask);
    % TODO handle the situation when a subset of ROIs are not transformed successfully
end
