function saveIdentityTransform(anatomyList, referenceAnatomy,...
                               trialNameList, refTrialName,...
                               transformParam, offsetYxList,...
                               saveDir)
    matDir = fullfile(saveDir, 'TransformationsMat');
    if ~exist(matDir, 'dir')
        mkdir(matDir)
    end
    
    transformStack = Bunwarpj.Transformation.empty();
    transfomrInvStack = Bunwarpj.Transformation.empty();
    for k=1:length(trialNameList)
        transformStack(k) = Bunwarpj.Transformation('type', 'identity');
        transformInvStack(k) = Bunwarpj.Transformation('type', 'identity');
    end
    
    % Bunwarpj.convertRawToMat(rawTransFile, fullfile(matDir,));
    % Bunwarpj.convertRawToMat(rawTransInvFile, fullfile(matDir,));
    transform = Bunwarpj.Transformation('type', 'identity');
    for k=1:length(trialNameList)
        trialName = trialNameList{k};
        save(fullfile(matDir, strcat(trialName, ".mat")), 'transform');
        save(fullfile(matDir, strcat(trialName, "_inverse.mat")), 'transform');
    end        
    
    
    save(fullfile(saveDir, 'transformMeta.mat'),...
         'anatomyList',...
         'referenceAnatomy',...
         'trialNameList',...
         'refTrialName',...
         'transformParam',...
         'offsetYxList');
end
