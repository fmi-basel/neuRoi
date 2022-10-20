function computeBunwarpj(anatomyList, referenceAnatomy,...
                         bunwarpjDir, transformParam)
    if transformParam.normParam.useClahe || transformParam.normParam.useHistoEqual
        anatomyList = normImages(anatomyList)
        referenceAnatomy = normImages(referenceAnatomy)
        % (anatomyList,BUnwarpJFolder,transformParam.Reference_idx,transformParam.CLAHE,transformParam.CLAHE_Parameters);
    end

    BUnwarpJ.computeTransformation(anatomyList, referenceAnatomy,...
                                   bunwarpjDir, transformParam);
end

