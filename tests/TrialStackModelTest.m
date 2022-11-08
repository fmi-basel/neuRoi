classdef TrialStackModelTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        stackModel
    end
       
    methods(TestClassSetup)
        function createData(testCase)
            stack = createStack();
            templateIdx = 1;
            testCase.stackModel = trialStack.TrialStackModel(stack.trialNameList,...
                                                             stack.anatomyStack,...
                                                             stack.responseStack,...
                                                             'roiArrStack', stack.roiArrStack,...
                                                             'transformStack', stack.transformStack,...
                                                             'transformInvStack', stack.transformInvStack,...
                                                             'doSummarizeRoiTags', true);
        end
    end

    methods(Test)
        function testRoi(testCase)
            stackModel = testCase.stackModel;

            % add/update/delete ROI in current trial
            % apply ROI add/delete to trial stack

            stackModel.selectTrial(1);
            position = [65,45; 65,46; 66,45; 66,46];
            roi = roiFunc.RoiM(position);
            stackModel.addRoi(roi); % ROI #5
            stackModel.deleteRoi(3);
            
            stackModel.selectTrial(2);
            position = [61,41; 62,41; 62,42; 63,42];
            roi = roiFunc.RoiM(position);
            stackModel.addRoi(roi); % ROI #6
            
            position = [64,43; 64,44; 65,43; 65,44];
            roi = roiFunc.RoiM(position);
            stackModel.addRoi(roi); % ROI #7
            
            position = [40,90; 40,91; 42,90; 42,91];
            freshRoi = roiFunc.RoiM(position);
            stackModel.updateRoi(3, freshRoi);
            stackModel.deleteRoiInStack(2);
            stackModel.deleteRoiInStack(3);
            
            stackModel.selectTrial(3);
            position = [55,82; 56,82; 55,83; 56,83];
            freshRoi = roiFunc.RoiM(position);
            stackModel.updateRoi(1, freshRoi);
            
            stackModel.selectTrial(2);
            stackModel.selectRois([6, 7]);
            stackModel.addRoisInStack('region1');
  
            % Verify
            % trial 1
            tags = testCase.getTags(1, 'diff');
            testCase.verifyEqual(tags, [5]);
            tags = testCase.getTags(1, 'region1');
            testCase.verifyEqual(tags, [1, 6, 7]);
            tags = testCase.getTags(1, 'region2');
            testCase.verifyEqual(tags, [4]);

            % trial 2
            tags = testCase.getTags(2, 'diff');
            testCase.verifyEqual(length(tags), 0);
            tags = testCase.getTags(2, 'region1');
            testCase.verifyEqual(tags, [1, 6, 7]);
            tags = testCase.getTags(2, 'region2');
            testCase.verifyEqual(tags, [4]);
            % updated roi 3

            % trial 3
            tags = testCase.getTags(3, 'diff');
            testCase.verifyEqual(length(tags), 0);
            tags = testCase.getTags(3, 'region1');
            testCase.verifyEqual(tags, [1, 6, 7]);
            tags = testCase.getTags(3, 'region2');
            testCase.verifyEqual(tags, [4]);
            % updated roi 1
        end
    end
    
    methods
        function tags = getTags(testCase, trialIdx, groupName)
            [rois, tags] = testCase.stackModel.roiArrStack{trialIdx}.getRoisInGroup(groupName);
        end
    end
end
