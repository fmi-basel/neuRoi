function computeTransformation(trialImages, referenceImage,...
                               trialNameList, refTrialName,...
                               saveDir, transformParam,...
                               offsetYxList)
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

        % If you have an offset
        offsetYx = offsetYxList{i};
        trialImg = imtranslate(trialImg, [offsetYx(2), offsetYx(1)], 'FillValues', 0);

        % Optional: match histogram if intensities differ
        trialImg = imhistmatch(trialImg, refImg);

        % Compute flow from T -> refImg
        % reset(opticFlow);
        % estimateFlow(opticFlow, T);        % T is 'previous'
        % flow = estimateFlow(opticFlow, refImg);  % refImg is 'current'

        options.alpha = 1.5;
        options.levels = 100;
        options.min_level = -1;
        options.eta = 0.8;
        options.update_lag = 5;
        options.iterations = 50;
        options.a_smooth = 1;
        options.a_data = 0.45;

        flow = nrOpticFlow.core.get_displacement( ...
                refImg, ... % fixed
                trialImg, ... % moving
                'sigma', 0.001, ...
                'alpha', options.alpha, ...
                'levels', options.levels, ...
                'min_level', options.min_level, ...
                'eta', options.eta, ...
                'update_lag', options.update_lag, ...
                'iterations', options.iterations, ...
                'a_smooth', options.a_smooth, 'a_data', options.a_data);

        % Save flow in .mat
        save(fullfile(matDir, trialName + ".mat"), 'flow');
        fprintf("Computed multi-scale flow for %s\n", trialName);

        % Compute the inverse flow
        inverse_flow = nrOpticFlow.core.get_displacement( ...
                trialImg, ... % fixed
                refImg, ... % moving
                'sigma', 0.001, ...
                'alpha', options.alpha, ...
                'levels', options.levels, ...
                'min_level', options.min_level, ...
                'eta', options.eta, ...
                'update_lag', options.update_lag, ...
                'iterations', options.iterations, ...
                'a_smooth', options.a_smooth, 'a_data', options.a_data);
        save(fullfile(matDir, trialName + "_inverse.mat"), 'inverse_flow');
        fprintf("Computed multi-scale inverse flow for %s\n", trialName);
    end
end
