function transformStack = loadTransformStack(bunwarpjDir, refTrialName,...
                                             trialNameList, transformType)
    if strcmp(transformType, 'forward')
        appendix = '';
    elseif strcmp(transformType, 'inverse')
        appendix = '_inverse';
    end
    transformStack = Bunwarpj.Transformation.empty();
    matDir = fullfile(bunwarpjDir, 'TransformationsMat');
    for k=1:length(trialNameList)
        trialName = trialNameList{k};
        if strcmp(trialName, refTrialName)
            transformStack(k) = Bunwarpj.Transformation('type', 'identity');
        else
            tFile = fullfile(matDir, sprintf('%s%s.mat', trialName, appendix));
            foo = load(tFile);
            transformStack(k) = foo.transform;
        end
    end
end

