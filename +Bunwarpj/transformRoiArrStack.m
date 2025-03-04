function roiArrStack = transformRoiArrStack(templateRoiArr, transformStack, offsetYxList)
    roiMap = templateRoiArr.convertToMask();
    roiArrStack = roiFunc.RoiArray.empty();
    for k=1:length(transformStack)
        tMask= Bunwarpj.applyTransformation(roiMap, transformStack(k), offsetYxList(k, :));
        roiArrStack(k) = roiFunc.RoiArray('maskImg', tMask);
    end
end

