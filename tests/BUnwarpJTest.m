classdef BUnwarpJTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        dirs
        movieStructList
        anatomyFileList
    end
       
    methods(TestClassSetup)
        function createData(testCase)
            tmpDir = 'tmp';
            if ~exist(tmpDir, 'dir')
                mkdir(tmpDir)
            end
            transformDir = fullfile(tmpDir, 'Transformations');
            rawTransformDir = fullfile(tmpDir, 'TransformationsRaw');
            
            if ~exist(transformDir, 'dir')
                mkdir(transformDir)
            end
            
            if ~exist(rawTransformDir, 'dir')
                mkdir(rawTransformDir)
            end
            
            testDirs.tmpDir = tmpDir;
            testDirs.transformDir = transformDir;
            testDirs.rawTransformDir = rawTransformDir;
            testCase.dirs = testDirs;
            
            testCase.movieStructList = createTestMovies();
            testCase.anatomyFileList = saveTestAnatomy(tmpDir, testCase.movieStructList);
            
            % testCase.addTeardown(@rmdir, tmpDir, 's')
        end
    end

    methods(Test)
        function testBUnwarpJ(testCase)
            trialImages = cellfun(@(x) fullfile(testCase.dirs.tmpDir, x),...
                                   testCase.anatomyFileList(2:end),...
                                   'UniformOutput', false);
            referenceImage = fullfile(testCase.dirs.tmpDir, testCase.anatomyFileList{1});
            useSift = false;
            BUnwarpJ.computeTransformation(trialImages, referenceImage,...
                                  testCase.dirs.transformDir,...
                                  testCase.dirs.rawTransformDir,...
                                  useSift);
            tFileList = cellfun(@(x) fullfile(testCase.dirs.transformDir,...
                                              strrep(x, '.tif', '_transformation.txt')),...
                                testCase.anatomyFileList(2:end),...
                                'UniformOutput', false);
            rtFileList = cellfun(@(x) fullfile(testCase.dirs.rawTransformDir,...
                                               strrep(x, '.tif', '_transformationRaw.txt')),...
                                 testCase.anatomyFileList(2:end),...
                                 'UniformOutput', false);
            filesExist = cellfun(@(x) exist(x, 'file'), [tFileList, rtFileList]);
            testCase.verifyTrue(all(filesExist));
            
            templateMask = testCase.movieStructList{1}.templateMask;
            masks = BUnwarpJ.transformMasks(templateMask, rtFileList);
            
            for k=1:2
                tmask = squeeze(masks(k, :, :));
                maskSize = size(tmask);
                err = mean(mean(abs(tmask - testCase.movieStructList{k+1}.mask)));
                testCase.verifyLessThanOrEqual(err, 0.05)
            end
        end
    end

end


function movieStructList = createTestMovies()
    movieStructList = {};
    movieStructList{1} = createMovie();
    affineMat2 = [1 0 0; 0 1 0; -5 8 1];
    movieStructList{2}= createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    affineMat3 = [1.2 0 0; 0.1 1 0; -20 8 1];
    movieStructList{3}= createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end
