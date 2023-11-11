function roiArr = convertRoiFreehandArrToRoiArr(roiFhArr, imageSize)
    roiList = roiFunc.RoiM.empty();

    for k=1:length(roiFhArr)
        roiList(k) = roiFunc.convertRoiFreehandToRoiM(roiFhArr(k), imageSize);
    end
    
    roiArr = roiFunc.RoiArray('imageSize', imageSize,...
                              'roiList', roiList);
end
