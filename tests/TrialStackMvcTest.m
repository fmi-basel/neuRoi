classdef TrialStackMvcTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        stackModel
        stackView
        stackCtrl
    end

    methods(TestClassSetup)
        function createData(testCase)
            stack = createStack();
            templateIdx = 1;
            stackModel = trialStack.TrialStackModel(stack.trialNameList,...
                                                    stack.anatomyStack,...
                                                    stack.responseStack,...
                                                    'roiArrStack', stack.roiArrStack,...
                                                    'transformStack', stack.transformStack,...
                                                    'transformInvStack', stack.transformInvStack,...
                                                    'doSummarizeRoiTags', true);
            testCase.stackCtrl = trialStack.TrialStackController(stackModel)
        end
    end

    methods(Test)
        function testTrial(testCase)
            stackCtrl = testCase.stackCtrl;
            stackCtrl.model.currentTrialIdx = 1;
            % verify map data in view
            stackCtrl.model.currentTrialIdx = 2;
            % verify map data in view
        end
        
        function testRoi(testCase)
            stackCtrl = testCase.stackCtrl;
            stackCtrl.model.currentTrialIdx = 1;
            
            stackCtrl.drawRoi();
            stackCtrl.replaceRoiByDrawing();
            stackCtrl.moveRoi();
            stackCtrl.selectRoi();
            stackCtrl.deleteSelectedRoi();
            
            stackCtrl.model.currentTrialIdx = 2;
            stackCtrl.drawRoi();

            stackCtrl.model.currentTrialIdx = 1;
            stackCtrl.selectRoi();
            stackCtrl.addRoisToGroup();
            
            stackCtrl.model.currentTrialIdx = 2;
            % verify roi tags and roi map in view
        end
    end

end
