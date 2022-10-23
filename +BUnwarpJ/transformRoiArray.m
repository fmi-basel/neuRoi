function roiArrayStack = transformRoiArray(templateRoiArray,trialNameList,refTrialName,transformDir)
roiMap = templateRoiArray.convertToMask();
    for k=1:length(trialNameList)
        trialName = trialNameList{k};
        if strcmp(trialName, refTrialName)
            roiArr = templateRoiArray;
        else
            transformName = strcat(trialName,'.mat');
            outputMask= BUnwarpJ.applyTransformation(roiMap,fullfile(transformDir,'TransformationsMat',transformName));
            % convert outputMask to RoiArray
            roiArr = roiFunc.RoiArray('maskImg',outputMask);
        end
        roiArr.meta.trialName = trialName;
        roiArrayStack(k)=roiArr;
        tempString= strcat(int2str(k), " of ",int2str(length(trialNameList)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
    end
end
