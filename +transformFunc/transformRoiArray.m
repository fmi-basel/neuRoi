function troiArr = transformRoiArray(roiArr, transform)
    roiMap = roiArr.convertToMask();
    interpolationMethod = 'nearest';
    outputMask= nrOpticFlow.applyTransformation(roiMap, transform, interpolationMethod);
    troiArr = roiFunc.RoiArray('maskImg',outputMask);
    % TODO handle the situation when a subset of ROIs are not transformed successfully
end
