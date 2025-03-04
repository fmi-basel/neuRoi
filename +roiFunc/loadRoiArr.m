function roiArr = loadRoiArr(filePath, mapSize)
    foo = load(filePath);
    % Downward compatibility with polygon ROIs (RoiFreehand)
    type_correct = false;
    if isfield(foo, 'roiArr')
        if isa(foo.roiArr, 'roiFunc.RoiArray')
            type_correct = true;
            roiArr = foo.roiArr;
        end
    else
        if isa(foo.roiArray, 'RoiFreehand')
            type_correct = true;
            roiArr = roiFunc.convertRoiFreehandArrToRoiArr(foo.roiArray,...
                                                           mapSize);
        else
            % roiArray is an array of RoiM
            type_correct = true;
            roiArr = roiFunc.RoiArray('roiList', foo.roiArray,...
                                      'imageSize', mapSize);
        end
    end
    
    if ~type_correct
        msg = 'The ROI file should contain roiArr as type roiFunc.RoiArray or as in the old version (v0.x.x) contain roiArray as type RoiFreehand';
        error(msg)
    end
end

