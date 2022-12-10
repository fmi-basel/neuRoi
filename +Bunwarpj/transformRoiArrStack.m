function roiArrStack = transformRoiArrStack(templateRoiArr, transformStack)
    roiMap = templateRoiArr.convertToMask();
    roiArrStack = roiFunc.RoiArray.empty();
    for k=1:length(transformStack)
        roiArrStack(k) = Bunwarpj.transformRoiArray(roiMap, transformStack(k));
    end
end

