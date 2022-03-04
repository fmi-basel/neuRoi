function roiArrayStack = transformRoiArray(templateRoiArray,roiType,rawFileList,transformDir)
roiMap = templateRoiArray.convertToMask();

    for i=1:length(rawFileList)
        [~,trialName,~] = fileparts(rawFileList{i});
        transformName = iopath.modifyFileName(rawFileList{i},'anatomy_','_Norm_transformationRaw','txt');
        outputMask= BUnwarpJ.fcn_ApplyRawTransformation(roiMap,fullfile(transformDir,'TransformationsRaw',transformName));
        % convert outputMask to RoiArray
        roiArr = roiFunc.RoiArray('maskImg',outputMask);
        roiArr.meta.trialName = trialName;
        roiArrayStack(i)=roiArr;
        tempString= strcat(int2str(i), " of ",int2str(length(rawFileList)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
    end

    
end

