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
            
            affineMats = {};
            affineMats{1} = [1 0 0; 0 1 0; -5 8 1];
            affineMats{2} = [1 0 0; 0 1 0; 10 -20 1];
            movieStructList = createTestMovies(affineMats{1}, affineMats{2});
            testCase.anatomyArray = ;
            testCase.responseArray = testCase.anatomyArray;
            
            testCase.templateRoiArr = roiFunc.RoiArray('maskImg', templateMask);;
            testCase.roiArrStack = ;

            
            transfomrStack = emptyStructArray;
            for k=1:2
                transformStack(k) = createTransform(imageSize, affineMats{k}[3, 1:2])
            end
        end
    end

    methods(Test)
        function testTrialStackModel(testCase)
            model = trialStack.TrialStackModel(trialNameList,...
                                               anatomyArray,...
                                               responseArray,...
                                               templateRoiArr,...
                                               roiArrStack,...
                                               transformStack)
        end
    end
end


function movieStructList = createTestMovies(affineMat2, affineMat3)
    movieStructList = {};
    movieStructList{1} = createMovie();
    movieStructList{2}= createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    movieStructList{3}= createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end

function transf = createTransform(imageSize, offsetYx)
    transf.xcorr = repmat((1:imageSize(2)) + offsetYx(1), [imageSize(1), 1]);
    transf.ycorr = repmat((1:imageSize(1)) + offsetYx(2), [imageSize(2), 1]);
    transf.width = imageSize(2);
    transf.height = imageSize(1);
end
