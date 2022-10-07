classdef NrModelTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        dirs
        movieStructList
        myexp
    end
       
    methods(TestClassSetup)
        function createData(testCase)
            tmpDir = 'tmp';
            if ~exist(tmpDir, 'dir')
                mkdir(tmpDir)
            end
            
            resultDir = fullfile(tmpDir, 'results');
            if ~exist(resultDir, 'dir')
                mkdir(resultDir)
            end

            testDirs.tmpDir = tmpDir;
            testDirs.resultDir = resultDir;
            
            movieStructList = createTestMovies();
            rawFileList = saveTestMovies(tmpDir, movieStructList);
            

            expInfo.name = 'test_exp';
            expInfo.frameRate = 10;
            expInfo.nPlane = 1;

            myexp = NrModel('rawDataDir', tmpDir,...
                            'rawFileList', rawFileList,...
                            'resultDir', resultDir,...
                            'expInfo', expInfo);

            templateMask = movieStructList{1}.templateMask;
            maskDir = myexp.getDefaultDir('mask');
            if ~exist(maskDir, 'dir')
                mkdir(maskDir)
            end
            templateMaskFile = fullfile(maskDir, 'template_mask.tif');
            movieFunc.saveTiff(uint16(templateMask), templateMaskFile);
            
            testCase.dirs = testDirs;
            testCase.movieStructList = movieStructList;
            testCase.myexp = myexp;
            
            % testCase.addTeardown(@rmdir, tmpDir, 's')
        end
    end

    methods(Test)
        function testCalculateBUnwarpJ(testCase)
            myexp = testCase.myexp;
            myexp.processRawData()
            
            myexp.ReferenceTrialIdx = 1;
            myexp.TransformationName = 'transf';
            
            myexp.
            
            
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
% loadTrials

% arrangeTrialTable


% batchExtractTimeTrace
