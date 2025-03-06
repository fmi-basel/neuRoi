function roiArrStack = transformRoiArrStack(templateRoiArr, transformStack)
    roiMap = templateRoiArr.convertToMask();
    roiArrStack = roiFunc.RoiArray.empty();
    for k=1:length(transformStack)
        tMask= nrOpticFlow.applyTransformation(roiMap, transformStack(k));
        roiArrStack(k) = roiFunc.RoiArray('maskImg', tMask);
    end
end

