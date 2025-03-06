classdef OpticFlowTest < matlab.unittest.TestCase
    properties
        referencePath
        trialPath
        saveDir
        trialName
        matFile
    end

    methods (TestMethodSetup)
        function setupTest(testCase)
            % Hard-coded test images for demonstration
            testCase.referencePath = fullfile('test_images', 'anatomy_Fish4_odorX_022__Norm.tif');
            testCase.trialPath     = fullfile('test_images', 'anatomy_Fish4_odorX_001__Norm.tif');

            testCase.saveDir       = 'test_output';
            testCase.trialName     = 'test_trial';
            testCase.matFile       = fullfile(testCase.saveDir, 'TransformationsMat', 'test_trial.mat');
        end
    end

    methods (Test)
        function testComputeTransformation(testCase)
            % Clean up any old results
            if exist(testCase.saveDir, 'dir')
                rmdir(testCase.saveDir, 's');
            end
            mkdir(testCase.saveDir);

            % Create dummy transformParam and offset
            transformParam = struct(); 
            offsetYxList   = {[0, 0]}; 
            
            % Run computeTransformation
            nrOpticFlow.computeTransformation( ...
                {testCase.trialPath}, ...
                testCase.referencePath, ...
                {testCase.trialName}, ...
                'refTrialName', ...
                testCase.saveDir, ...
                transformParam, ...
                offsetYxList ...
            );
            
            % Check that the .mat file was created
            testCase.assertTrue(exist(testCase.matFile, 'file') == 2, ...
                "No transformation file created!");
        end
        
        function testApplyTransformation(testCase)
            % Verify that flow file was created
            testCase.assumeTrue(exist(testCase.matFile, 'file') == 2, ...
                "Skipping: transformation file missing.");

            % Load the saved flow fields (u, v)
            flowmat = load(testCase.matFile); % has 'u', 'v'
            transform.type = 'opticFlow';
            transform.flowField = flowmat.flow;

            % Load images
            refImg   = im2double(imread(testCase.referencePath));
            trialImg = im2double(imread(testCase.trialPath));

            % Apply transformation to trial => should match reference
            outImg = nrOpticFlow.applyTransformation(trialImg, transform);

            % Check sizes
            testCase.assertSize(outImg, size(refImg), ...
                "Transformed trial image size mismatch with reference.");

            % -----------------------------
            % 1) Display (Trial, Warped Trial, Reference)
            % -----------------------------
            figure('Name','Alignment Check');
            subplot(1,3,1); imshow(trialImg); title('Trial (Input)');
            subplot(1,3,2); imshow(outImg);   title('Warped Trial');
            subplot(1,3,3); imshow(refImg);   title('Reference');

            % -----------------------------
            % 2) Display the Flow Field (u,v) as a quiver plot
            % -----------------------------
            figure('Name','Flow Field');
            imshow(trialImg); 
            hold on;

            % Downsample the flow for a cleaner quiver plot
            flowField = transform.flowField;
            step = 15;
            [cols, rows] = meshgrid(1:step:size(flowField,2), 1:step:size(flowField,1));

            U = flowField(1:step:end, 1:step:end, 1);
            V = flowField(1:step:end, 1:step:end, 2);

            quiver(cols, rows, U, V, 0, 'y'); % scale=0 => no automatic scaling
            title('Estimated Flow Field (Trial \rightarrow Reference)');

            % -----------------------------
            % 3) Optionally save the images as a stack TIF
            % -----------------------------
            savePath = fullfile(testCase.saveDir, 'test_stack.tif');
            imwrite(trialImg, savePath, 'WriteMode', 'overwrite');
            imwrite(refImg,   savePath, 'WriteMode', 'append');
            imwrite(outImg,   savePath, 'WriteMode', 'append');

            disp('Check the quiver plot (flow) and the warped image vs. reference for correctness.');
        end
    end
end
