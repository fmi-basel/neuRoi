function transformStack = loadTransformStack(bunwarpjDir,trialNameList, transformType)
    transformMeta = load(fullfile(bunwarpjDir, 'transformMeta.mat'));
    refTrialName = transformMeta.refTrialName;

    if strcmp(transformType, 'forward')
        appendix = '';
    elseif strcmp(transformType, 'inverse')
        appendix = '_inverse';
    end
    transformStack = transformFunc.Transformation.empty();
    matDir = fullfile(bunwarpjDir, 'TransformationsMat');
    for k=1:length(trialNameList)
        trialName = trialNameList{k};
        if strcmp(trialName, refTrialName)
            transformStack(k) = transformFunc.Transformation('type', 'identity');
        else
            tFile = fullfile(matDir, sprintf('%s%s.mat', trialName, appendix));
            foo = load(tFile);
            transformStack(k) = foo.transform;
        end
    end
end

