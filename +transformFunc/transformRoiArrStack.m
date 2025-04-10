function roiArrStack = transformRoiArrStack(templateRoiArr, transformStack)
    roiMap = templateRoiArr.convertToMask();
    roiArrStack = roiFunc.RoiArray.empty();
    interpolationMethod = 'nearest';
    for k=1:length(transformStack)
        tMask= nrOpticFlow.applyTransformation(roiMap, transformStack(k), interpolationMethod);
        roiArrStack(k) = roiFunc.RoiArray('maskImg', tMask);
    end
end