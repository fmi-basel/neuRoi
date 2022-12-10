function troiArr = transformRoiArray(roiMap, transform)
    outputMask= Bunwarpj.applyTransformation(roiMap, transform);
    troiArr = roiFunc.RoiArray('maskImg',outputMask);
    % TODO handle the situation when a subset of ROIs are not transformed successfully
end
