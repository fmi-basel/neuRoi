function computeTransformation(trialImages, referenceImage,...
                               trialNameList, refTrialName,...
                               saveDir, transformParam)
    % Prepare output directory
    matDir = fullfile(saveDir, 'TransformationsMat');
    if ~exist(matDir, 'dir')
        mkdir(matDir);
    end

    % Load reference image
    refImg = im2double(imread(referenceImage));

    % Create a multi-scale Lucas-Kanade optical flow estimator
    opticFlow = opticalFlowLK( ...
        'NoiseThreshold', 0.001, ...
        'NumPyramidLevels', 5, ...
        'PyramidScale', 0.5 ...
    );

    for i = 1:length(trialImages)
        trialName = trialNameList{i};
        trialImg = im2double(imread(trialImages{i}));
        % Optional: match histogram if intensities differ
        trialImg = imhistmatch(trialImg, refImg);


        options.alpha = 1.5;
        options.levels = 100;
        options.min_level = -1;
        options.eta = 0.8;
        options.update_lag = 5;
        options.iterations = 50;
        options.a_smooth = 1;
        options.a_data = 0.45;

        % Compute flow from T -> refImg
        transform = nrOpticFlow.computeTransf(refImg, trialImg, options);
        % Save flow in .mat
        save(fullfile(matDir, trialName + ".mat"), 'transform');
        fprintf("Computed multi-scale flow for %s\n", trialName);

        % Compute the inverse flow
        transform = nrOpticFlow.computeTransf(trialImg, refImg, options);
        save(fullfile(matDir, trialName + "_inverse.mat"), 'transform');
        fprintf("Computed multi-scale inverse flow for %s\n", trialName);
    end
end