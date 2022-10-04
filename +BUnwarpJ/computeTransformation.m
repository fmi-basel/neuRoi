function computeTransformation(trialImages, referenceImage,...
                               transformFolder, rawTransformFolder,...
                               useSift)
    imagejPaths = BUnwarpJ.getImagejPaths();
    for k=1:length(imagejPaths)
        javaaddpath(imagejPaths{k})
    end

    %ImageJ Loader
    ImageJ_LoaderEngine=ij.io.Opener();

    for i=1:length(trialImages)
        tempTrial=ImageJ_LoaderEngine.openImage(trialImages(i));

        [filepath,name,ext] = fileparts(trialImages(i));
        
        if useSift==true %https://imagej.net/plugins/feature-extraction
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

        reference=ImageJ_LoaderEngine.openImage(referenceImage);
        tempString= strcat("Start calculating transformation at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
        %calculate Transformation
        transformationGridStart =0;
        transformationGridEnd =2;
        transf=bunwarpj.bUnwarpJ_.computeTransformationBatch(...
            tempTrial,... %reference target image
            reference,... %warped source image
            tempTrial.getMask,...
            reference.getMask,...
            1,... %accuracy mode (0 - Fast, 1 - Accurate, 2 - Mono)
            0,... %image subsampling factor (from 0 to 7, representing 2^0=1 to 2^7 = 128)
            transformationGridStart,... %(0 - Very Coarse, 1 - Coarse, 2 - Fine, 3 - Very Fine)
            transformationGridEnd,... %(0 - Very Coarse, 1 - Coarse, 2 - Fine, 3 - Very Fine, 4 - Super Fine)
            0,... %divergence weight
            0,... %curl weight
            LandmarksWeights,... %landmark weight
            ImageWeigths,... %image similarity weight
            10,... %consistency weight
            0.01); %stopping threshold

        %Save Transformation
        transf.saveDirectTransformation(fullfile(transformFolder,strcat(name,"_transformation.txt")));
        transf.saveInverseTransformation(fullfile(transformFolder,strcat(name,"_transformationInverse.txt")));

        %Transform to raw transformation
        tempTrial.show();
        bunwarpj.bUnwarpJ_.convertToRaw(fullfile(transformFolder,strcat(name,"_transformation.txt")),fullfile(rawTransformFolder,strcat(name,"_transformationRaw.txt")),strcat(name,ext));
        bunwarpj.bUnwarpJ_.convertToRaw(fullfile(transformFolder,strcat(name,"_transformationInverse.txt")),fullfile(rawTransformFolder,strcat(name,"_transformationInverseRaw.txt")),strcat(name,ext));
        
        if useSift==true
            tempTrial.close();
            reference.close();
        else
            tempTrial.close();
        end

        tempString= strcat(int2str(i), " of ",int2str(length(trialImages)), " transformation calculated at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);

    end
    reference.close();
end

