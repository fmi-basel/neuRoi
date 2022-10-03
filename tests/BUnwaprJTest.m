classdef BUnwaprJTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        trial
        anatomy
        timeTraceMat
    end
       
    methods(TestClassSetup)
        function addBankAccountClassToPath(testCase)
            p = path;
            testCase.addTeardown(@path,p)
            addpath(fullfile(matlabroot,'help','techdoc','matlab_oop', ...
                'examples'))
        end
    end

    methods(TestMethodSetup)
        function createXXXX(testCase)
            xxxx createTestExperiment
            testCase.addTeardown(@delete, testCase.exp)
            rmDirectory(tmpExpDir)
        end
    end

    methods(Test)
        function testCalcAnatomy (testCase)
            [mapData, mapOption] = testCase.trial.calcAnatomy();
            testCase.verifyEqual(mapData, testCase.anatomy);
        end
        
        function testExtraceTimeTrace(testCase)
            position = [3,3; 3,5; 5,3; 5,5];
            freshRoi = RoiFreehand(position);
            testCase.trial.addRoi(freshRoi);
            [timeTraceMat, roiArray] = testCase.trial.extractTimeTraceMat();
            roiIdx = 1;
            timeTrace = timeTraceMat(roiIdx, :);
            testCase.verifyEqual(timeTrace, testCase.timeTraceMat(roiIdx, :));
        end
    end

end
