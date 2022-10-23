function roiArrayStack = transformRoiArray(templateRoiArray,trialNameList,refTrialName,transformDir)
roiMap = templateRoiArray.convertToMask();
    for k=1:length(trialNameList)
        trialName = trialNameList{k};
        if strcmp(trialName, refTrialName)
            roiArr = templateRoiArray;
        else
            transformName = iopath.modifyFileName(trialName,'','_transformationRaw','txt');
            outputMask= BUnwarpJ.fcn_ApplyRawTransformation(roiMap,fullfile(transformDir,'TransformationsRaw',transformName));
            % convert outputMask to RoiArray
            roiArr = roiFunc.RoiArray('maskImg',outputMask);
        end
        roiArr.meta.trialName = trialName;
        roiArrayStack(k)=roiArr;
        tempString= strcat(int2str(k), " of ",int2str(length(trialNameList)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
    end
end
