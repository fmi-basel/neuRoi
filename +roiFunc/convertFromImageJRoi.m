function roiArray=convertFromImageJRoi(jroiArray)
    roiArray = RoiFreehand.empty();
    for k=1:length(jroiArray)
        jroi = jroiArray{k};
        roi = RoiFreehand(jroi.mnCoordinates);
        roi.tag = k;
        roiArray(end+1) = roi;
    end
end

