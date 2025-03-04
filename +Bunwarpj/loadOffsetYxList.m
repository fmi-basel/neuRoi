function offsetYxList = loadOffsetYxList(bunwarpjDir, trialNameList)
    transformMeta = load(fullfile(bunwarpjDir, 'transformMeta.mat'));
    refTrialName = transformMeta.refTrialName;
    tmOffsetYxList = transformMeta.offsetYxList;
    tmTrialNameList = transformMeta.trialNameList;
    
    nTrial = length(trialNameList); 
    offsetYxList = zeros(nTrial, 2);
    for k=1:nTrial
        trialName = trialNameList{k};
        if strcmp(trialName, refTrialName)
            offsetYxList(k, :) = [0, 0];
        else
            idx = find(strcmp(tmTrialNameList, trialName));
            if isempty(idx)
                error(sprintf('Trial %s not found in transformation', trialName))
            end
            offsetYxList(k, :) = tmOffsetYxList{idx};
        end
    end
end
