classdef BUnwarpJTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        dirs
        movieStructList
        anatomyFileList
    end
       
    methods(TestMethodSetup)
        function createData(testCase)
            tmpDir = 'tmp';
            if ~exist(tmpDir, 'dir')
                mkdir(tmpDir)
            end
            transformDir = 'Transformations';
            rawTransformDir = 'TransformationsRaw';
            
            if ~exist(transformDir, 'dir')
                    mkdir(transformDir)
            end
            
            if ~exist(rawTransformDir, 'dir')
                mkdir(transformDir)
            end
            
            testDirs.tmpDir = tmpDir;
            testDirs.transformDir = transformDir;
            testDirs.rawTransformDir = rawTransformDir;
            testCase.dirs = testDirs;
            testCase.addTeardown(@delete, testCase.dirs);

            testCase.movieStructList = createTestMovies();
            testCase.addTeardown(@delete, testCase.movieStructList)

            testCase.anatomyFileList = saveTestAnatomy(tmpDir, testCase.movieStructList);
            testCase.addTeardown(@delete, testCase.anatomyFileList)
            
            testCase.addTeardown(@rmdir, tmpDir)
        end
    end

    methods(Test)
        function testComputeTransformation(testCase)
            trialImages = cellfun(@(x) fullfile(testCase.dirs.tmpDir, x),...
                                   testCase.anatomyFileList,...
                                   'UniformOutput', false);
            referenceImage = fullfile(testCase.dirs.tmpDir, testCase.anatomyFileList{1});
            useSift = false;
            BUnwarpJ.computeTransformation(trialImages, referenceImage,...
                                  testCase.dirs.transformDir,...
                                  testCase.dirs.rawTransformDir,...
                                  useSift);
            % TODO verify results
            % testCase.verifyEqual(mapData, testCase.anatomy);
        end
        
        % function testTransformMask(testCase)
        %     position = [3,3; 3,5; 5,3; 5,5];
        %     freshRoi = RoiFreehand(position);
        %     testCase.trial.addRoi(freshRoi);
        %     [timeTraceMat, roiArray] = testCase.trial.extractTimeTraceMat();
        %     roiIdx = 1;
        %     timeTrace = timeTraceMat(roiIdx, :);
        %     testCase.verifyEqual(timeTrace, testCase.timeTraceMat(roiIdx, :));
        % end
    end

end
