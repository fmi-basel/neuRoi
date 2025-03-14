function computeTransformationWrapper(anatomyList, referenceAnatomy,...
                                      trialNameList, refTrialName,...
                                      transformParam, saveDir)
    if transformParam.normParam.useHistoEqual
        anatomyList = Bunwarpj.normImages(anatomyList, referenceAnatomy);
    elseif transformParam.normParam.useClahe
        normDir = fullfile(saveDir, 'normed_anatomy')
        if ~exist(normDir, 'dir')
            mkdir(normDir)
        end
        anatomyList = Bunwarpj.claheImages(anatomyList, transformParam.normParam.claheParam, normDir);
        referenceAnatomy = Bunwarpj.claheImages({referenceAnatomy},...
                                                transformParam.normParam.claheParam, normDir);
        referenceAnatomy = referenceAnatomy{1};
    end
    
    % TODO 2022-12-21 Bo Hu
    

    nrOpticFlow.computeTransformations(anatomyList, referenceAnatomy,...
                                       trialNameList, refTrialName,...
                                       saveDir, transformParam);
    
    save(fullfile(saveDir, 'transformMeta.mat'),...
         'anatomyList',...
         'referenceAnatomy',...
         'trialNameList',...
         'refTrialName',...
         'transformParam');
end

