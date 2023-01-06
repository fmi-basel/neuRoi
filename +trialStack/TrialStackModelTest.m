classdef TrialStackModelTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        stackModel
    end
       
    methods(TestClassSetup)
        function createData(testCase)
            stack = testUtils.createStack();
            templateIdx = 1;
            testCase.stackModel = trialStack.TrialStackModel(stack.trialNameList,...
                                                             stack.anatomyStack,...
                                                             stack.responseStack,...
                                                             'roiArrStack', stack.roiArrStack,...
                                                             'offsetYxList', stack.offsetYxList,...
                                                             'transformStack', stack.transformStack,...
                                                             'transformInvStack', stack.transformInvStack,...
                                                             'doSummarizeRoiTags', true);
        end
    end

    methods(Test)
        function testRoi(testCase)
            stackModel = testCase.stackModel;
            imageSize = size(stackModel.anatomyStack(:, :, 1));

            % add/update/delete ROI in current trial
            % apply ROI add/delete to trial stack

            stackModel.currentTrialIdx = 1;
            position = [65,45; 65,46; 66,45; 66,46];
            roi = roiFunc.RoiM('position', position);
            stackModel.addRoi(roi); % ROI #5
            stackModel.deleteRoi(3);
            
            stackModel.currentTrialIdx = 2;
            position = [61,41; 66,41; 66,46; 61,46];
            roi = testCase.createRoi(position(:,1), position(:,2), imageSize);
            stackModel.addRoi(roi); % ROI #6
            
            position = [71,31; 76,31; 76,36; 71,36];
            roi = testCase.createRoi(position(:,1), position(:,2), imageSize);
            stackModel.addRoi(roi); % ROI #7
            
            position = [40,90; 40,91; 42,90; 42,91];
            freshRoi = roiFunc.RoiM('position', position);
            stackModel.updateRoi(3, freshRoi);
            stackModel.deleteRoiInStack(2);
            stackModel.deleteRoiInStack(3);
            
            stackModel.currentTrialIdx = 3;
            position = [55,82; 56,82; 55,83; 56,83];
            freshRoi = roiFunc.RoiM('position', position);
            stackModel.updateRoi(1, freshRoi);
            
            stackModel.currentTrialIdx = 2;
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
            [rois, tags] = testCase.stackModel.roiArrStack(trialIdx).getRoisInGroup(groupName);
        end
        
        function roi = createRoi(testCase, xi, yi, imageSize)
            roiMask = poly2mask(xi, yi, imageSize(1), imageSize(2));
            [mposY,mposX] = find(roiMask);
            position = [mposX,mposY];
            roi = roiFunc.RoiM('position', position);
        end

    end
    
    
end
