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
        
            % Test add ROI
            rawRoi = images.roi.Freehand(stackCtrl.view.guiHandles.roiAxes,...
                                         'Position', [10, 10; 10, 20; 20, 20; 20, 10]);
            stackCtrl.addRawRoi(rawRoi);
            roiImgData = stackCtrl.view.getRoiImgData();
            mask = testCase.stack.movieStructList{1}.mask;
            mask(11:20, 11:20) = 5;
            testCase.verifyMse(roiImgData, mask, 0);
            
            % Move mouse to ROI #1 and select it by clicking
            pause(1.0);
            import java.awt.Robot;
            import java.awt.event.*;
            mouse = Robot;
            roi1p = [552, 1322];
            mouse.mouseMove(roi1p(1), roi1p(2));
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(0.5);
            testCase.verifyEqual(stackCtrl.model.roiArr.getSelectedTags, [1])

            % stackCtrl.selectRoi_Callback();
            
            % Test replace ROI
            stackCtrl.replaceRoiByDrawing([25, 33; 25, 44; 36, 44; 36, 33]);
            mask(find(mask==1)) = 0;
            mask(26:36, 34:44) = 1;
            roiImgData = stackCtrl.view.getRoiImgData();
            testCase.verifyMse(roiImgData, mask, 0);
            
            % Test moving ROI
            stackCtrl.enterMoveRoiMode();
            pause(0.1);
            mouse.mouseMove(roi1p(1)+30, roi1p(2)-5);
            pause(0.1);
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseMove(roi1p(1)+30, roi1p(2)-5+15);
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(1.0);
            % Double click to confirm moving
            mouse.mousePress(InputEvent.BUTTON1_MASK);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            mouse.mousePress(InputEvent.BUTTON1_MASK);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 

            % Move mouse to ROI #1 and select it by clicking
            pause(0.1);
            mouse.mouseMove(roi1p(1)+85, roi1p(2)+147);
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(0.1);
            stackCtrl.deleteSelectedRois();
            % stackCtrl.deleteSelectedRoi from all trials;
            
            % undo deletion from current trial
            % undo deletion from all trials
            
            % undo move ROI
            % undo redraw ROI
        
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

