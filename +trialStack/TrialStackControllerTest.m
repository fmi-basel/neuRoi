classdef TrialStackControllerTest < matlab.unittest.TestCase
% Tests the TrialModel class
    properties
        stackModel
        stackView
        stackCtrl
        stack
    end

    methods(TestClassSetup)
        function createData(testCase)
            stack = testUtils.createStack();
            templateIdx = 1;
            stackModel = trialStack.TrialStackModel(stack.trialNameList,...
                                                    stack.anatomyStack,...
                                                    stack.responseStack,...
                                                    'roiArrStack', stack.roiArrStack,...
                                                    'transformStack', stack.transformStack,...
                                                    'transformInvStack', stack.transformInvStack,...
                                                    'doSummarizeRoiTags', true);
            testCase.stack = stack;
            testCase.stackModel = stackModel;
            testCase.stackCtrl = trialStack.TrialStackController(testCase.stackModel);
        end
    end

    methods(Test)
        function testTrial(testCase)
            for k=1:3
                testCase.stackCtrl.model.currentTrialIdx = k;
                testCase.verifyMapImg(k, 0);
            end
        end
        
        function testRoi(testCase)
            stackCtrl = testCase.stackCtrl;
            stackCtrl.model.currentTrialIdx = 1;
        
            rawRoi = images.roi.Freehand(stackCtrl.view.guiHandles.roiAxes,...
                                         'Position', [10, 10; 10, 20; 20, 20; 20, 10]);
            stackCtrl.addRawRoi(rawRoi);
            roiImgData = stackCtrl.view.getRoiImgData();
            mask = testCase.stack.movieStructList{1}.mask;
            mask(11:20, 11:20) = 5;
            testCase.verifyMse(roiImgData, mask, 0);
            
            % Move to ROI #1 and select it by clicking
            pause(1.0);
            import java.awt.Robot;
            import java.awt.event.*;
            mouse = Robot;
            mouse.mouseMove(553, 1363); % relates to my personal location of open program instance
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(0.5);

            % stackCtrl.selectRoi_Callback();
            % stackCtrl.replaceRoiByDrawing([15, 15; 15, 25; 25, 25; 25, 15]);
        %     stackCtrl.moveRoi();
        %     stackCtrl.selectRoi();
        %     stackCtrl.deleteSelectedRoi();
        
        %     stackCtrl.model.currentTrialIdx = 2;
        %     stackCtrl.drawRoi();

        %     stackCtrl.model.currentTrialIdx = 1;
        %     stackCtrl.selectRoi();
        %     stackCtrl.addRoisToGroup();
        
        %     stackCtrl.model.currentTrialIdx = 2;
        %     % verify roi tags and roi map in view
        end
    end

    methods
        function verifyMapImg(testCase, trialIdx, thresh)
            mapImgData = testCase.stackCtrl.view.guiHandles.mapImage.CData;
            testCase.verifyMse(mapImgData, testCase.stack.movieStructList{trialIdx}.anatomy,...
                               thresh);
        end

        function verifyRoiImg(testCase, trialIdx, thresh)
            roiImgData = testCase.stackCtrl.getRoiImgData();
            testCase.verifyMse(roiImgData, testCase.stack.movieStructList{trialIdx}.mask,...
                               thresh);
        end

        function verifyMse(testCase, img1, img2, thresh)
            err = immse(img1, img2);
            testCase.verifyLessThanOrEqual(err, thresh);
        end
    end
end

