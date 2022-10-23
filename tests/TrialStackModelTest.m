classdef TrialStackModelTest < matlab.unittest.TestCase
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
            
            movieStructList = createTestMovies();
            testCase.anatomyArray = ;
            testCase.responseArray = testCase.anatomyArray;
            
            testCase.templateRoiArr = roiFunc.RoiArray('maskImg', templateMask);;
            testCase.roiArrStack = ;

            
            
            % How to generate transformations??
        end
    end

    methods(Test)
        function testTrialStackModel(testCase)
            model = trialStack.TrialStackModel(trialNameList,...
                                               anatomyArray,...
                                               responseArray,...
                                               templateRoiArr,...
                                               roiArrStack,...
                                               transformDir)
        end
    end
end


function movieStructList = createTestMovies()
    movieStructList = {};
    movieStructList{1} = createMovie();
    affineMat2 = [1 0 0; 0 1 0; -5 8 1];
    movieStructList{2}= createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    affineMat3 = [1 0 0; 0 1 0; 10 -20 1];
    movieStructList{3}= createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end

