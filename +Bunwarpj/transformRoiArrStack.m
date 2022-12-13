function roiArrStack = transformRoiArrStack(templateRoiArr, transformStack, offsetYxList)
    roiMap = templateRoiArr.convertToMask();
    roiArrStack = roiFunc.RoiArray.empty();
    for k=1:length(transformStack)
        roiArrStack(k) = Bunwarpj.transformRoiArray(roiMap, transformStack(k), offsetYxList{k});
    end
end

