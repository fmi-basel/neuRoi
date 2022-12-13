function offsetYxList = loadOffsetYxList(bunwarpjDir, trialNameList)
    transformMeta = load(fullfile(bunwarpjDir, 'transformMeta.mat'));
    refTrialName = transformMeta.refTrialName;
    tmOffsetYxList = transformMeta.offsetYxList;
    tmTrialNameList = transformMeta.trialNameList;
    
    offsetYxList = {};
    for k=1:length(trialNameList)
        trialName = trialNameList{k};
        if strcmp(trialName, refTrialName)
            offsetYxList{k} = [0, 0];
        else
            idx = find(strcmp(tmTrialNameList, trialName));
            if isempty(idx)
                error(sprintf('Trial %s not found in transformation', trialName))
            end
            offsetYxList{k} = tmOffsetYxList{idx};
        end
    end
end
