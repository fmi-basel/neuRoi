function computeTransformation(trialImages, referenceImage,...
                               trialNameList, refTrialName,...
                               saveDir, transformParam)
    rawTransformDir = fullfile(saveDir, 'TransformationsRaw');
    transformDir = fullfile(saveDir, 'Transformations');
    for folder={rawTransformDir, transformDir}
        if ~exist(folder{1}, 'dir')
            mkdir(folder{1})
        end
    end
    
    
    imagejPaths = BUnwarpJ.getImagejPaths();
    for k=1:length(imagejPaths)
        javaaddpath(imagejPaths{k})
    end

    %ImageJ Loader
    ImageJ_LoaderEngine=ij.io.Opener();
    if ~transformParam.useSift
        reference=ImageJ_LoaderEngine.openImage(referenceImage);
    end    
    for i=1:length(trialImages)
        trialName = trialNameList{i};
        tempTrial = ImageJ_LoaderEngine.openImage(trialImages(i));
        
        if transformParam.useSift==true %https://imagej.net/plugins/feature-extraction
            SIFTParameters = transformParam.SIFTParameters;
            reference=ImageJ_LoaderEngine.openImage(referenceImage);
            tempTrial.show();
            reference.show();
            SIFTObject= SIFT_ExtractPointRoi();
            SIFTObject.exec(tempTrial,reference, SIFTParameters.Initial_Gaussion_Blur,...
                            SIFTParameters.steps_per_scale_octave,...
                            SIFTParameters.minimum_image_size,...
                            SIFTParameters.maximum_image_size,...
                            SIFTParameters.feature_descriptor_size,...
                            SIFTParameters.feature_descriptor_orientation_bins,...
                            SIFTParameters.closest_next_closest_ratio,...
                            SIFTParameters.maximal_alignment_error,...
                            SIFTParameters.minimal_inlier_ratio,...
                            SIFTParameters.expected_transformation);
            LandmarksWeights=1;
            ImageWeigths=0;
        else
            LandmarksWeights=0;
            ImageWeigths=1;
        end

        if transformParam.useSift
            reference=ImageJ_LoaderEngine.openImage(referenceImage);
        end
        tempString= strcat("Start calculating transformation at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
        %calculate Transformation
        transf=bunwarpj.bUnwarpJ_.computeTransformationBatch(...
            tempTrial,... %reference target image
            reference,... %warped source image
            tempTrial.getMask,...
            reference.getMask,...
            1,... %accuracy mode (0 - Fast, 1 - Accurate, 2 - Mono)
            0,... %image subsampling factor (from 0 to 7, representing 2^0=1 to 2^7 = 128)
            transformParam.bunwarpjParam.transformationGridStart,... %(0 - Very Coarse, 1 - Coarse, 2 - Fine, 3 - Very Fine)
            transformParam.bunwarpjParam.transformationGridEnd,... %(0 - Very Coarse, 1 - Coarse, 2 - Fine, 3 - Very Fine, 4 - Super Fine)
            0,... %divergence weight
            0,... %curl weight
            LandmarksWeights,... %landmark weight
            ImageWeigths,... %image similarity weight
            10,... %consistency weight
            0.01); %stopping threshold

        
        %Save Transformation
        elasticTransFile = strcat(trialName,"_transformation.txt");
        elasticTransInvFile = strcat(trialName,"_transformationInverse.txt");
        transf.saveDirectTransformation(fullfile(transformDir, elasticTransFile));
        transf.saveInverseTransformation(fullfile(transformDir, elasticTransInvFile));

        %Transform to raw transformation
        tempTrial.show();
        targetTitile = tempTrial.getTitle();
        bunwarpj.bUnwarpJ_.convertToRaw(fullfile(transformDir, elasticTransFile),...
                                        fullfile(rawTransformDir,strcat(trialName,...
                                                          "_transformationRaw.txt")),...
                                        targetTitile);
        bunwarpj.bUnwarpJ_.convertToRaw(fullfile(transformDir, elasticTransInvFile),...
                                        fullfile(rawTransformDir,strcat(trialName,...
                                                          "_transformationInverseRaw.txt")),...
                                        targetTitile);
        
        if transformParam.useSift==true
            tempTrial.close();
            reference.close();
        else
            tempTrial.close();
        end

        tempString= strcat(int2str(i), " of ",int2str(length(trialImages)), " transformation calculated at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);

    end
end

