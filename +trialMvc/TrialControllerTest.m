classdef TrialControllerTest < matlab.unittest.TestCase
% Tests the TrialModel class
    properties
        model
        view
        ctrl
        movieStruct
    end

    methods(TestClassSetup)
        function createData(self)
            self.movieStruct = testUtils.createMovie();
            mockMovie.name = 'test_trial';
            mockMovie.rawMovie = self.movieStruct.rawMovie;
            mockMovie.meta.frameRate = 2;
            self.model = trialMvc.TrialModel('mockMovie', mockMovie);
            self.ctrl = trialMvc.TrialController(self.model);
            % import ROI from mask
            self.model.importRoisFromMask(self.movieStruct.mask);
        end
    end

    methods(Test)
        function testTrial(self)
            self.verifyMapImg(0);
        end
        
        function testSelectRoisByOverlay(self)
            pos = [45, 35; 105, 35; 105, 105; 45, 105];
            self.ctrl.selectRoisByOverlay(pos);
            disp(self.model.roiArr.getSelectedTags())
            self.verifyEqual(self.model.roiArr.getSelectedTags(), [2, 3])
        end
        
        function testRoi(self)
            ctrl = self.ctrl;

            % Test add ROI
            rawRoi = images.roi.Freehand(ctrl.view.guiHandles.roiAxes,...
                                         'Position', [10, 10; 10, 20; 20, 20; 20, 10]);
            ctrl.addRawRoi(rawRoi);
            roiMask = ctrl.view.getRoiMask();
            mask = self.movieStruct.mask;
            mask(11:20, 11:20) = 5;
            self.verifyMse(roiMask, mask, 0);
            
            % % Move mouse to ROI #1 and select it by clicking
            pause(1.0);
            import java.awt.Robot;
            import java.awt.event.*;
            mouse = Robot;
            roi1p = [2248, 494];%[556, 1537];
            mouse.mouseMove(roi1p(1), roi1p(2));
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
                                                       % pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(0.5);
            self.verifyEqual(ctrl.model.roiArr.getSelectedTags, [1])

            % Test replace ROI
            ctrl.replaceRoiByDrawing([33, 25; 44, 25; 44, 36; 33, 36]);
            mask(find(mask==1)) = 0;
            mask(26:36, 34:44) = 1;
            roiMask = ctrl.view.getRoiMask();
            self.verifyMse(roiMask, mask, 0);
            
            % Test moving ROI
            ctrl.enterMoveRoiMode();
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
            % pause(0.1);
            % mouse.mouseMove(roi1p(1)+85, roi1p(2)+147);
            % mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            % pause(0.1);
            % mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            % pause(0.1);
            % ctrl.deleteSelectedRois();
            
            % TODO fix delete ROIs
            
            % Add two ROIs
            pause(0.1);
            ctrl.addRoiByDrawing([73, 25; 84, 25; 84, 36; 73, 36]);
            ctrl.addRoiByDrawing([93, 85; 104, 85; 104, 96; 93, 96]);
            % Add the two ROIs in the stack
            mouse.mouseMove(roi1p(1)+187, roi1p(2)-8);
            mouse.keyPress(KeyEvent.VK_CONTROL);
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(0.1);
            mouse.keyRelease(KeyEvent.VK_CONTROL);
            
            ctrl.model.addRoiGroup('region1')
            disp(ctrl.model.roiArr.groupNames)
            ctrl.model.roiArr.currentGroupName = 'region1';
            
            notify(ctrl.model, 'roiGroupUpdated')
            % ctrl.deleteSelectedRoi from all trials;
            
            % undo deletion from current trial
            % undo deletion from all trials
            
            % undo move ROI
            % undo redraw ROI
        
            % verify roi tags and roi map in view
        end
        
    end

    methods
        function verifyMapImg(self, thresh)
            mapImgData = self.ctrl.view.guiHandles.mapImage.CData;
            self.verifyMse(mapImgData, self.movieStruct.anatomy,...
                               thresh);
        end

        function verifyRoiImg(self, thresh)
            roiImgData = self.ctrl.getRoiImgData();
            self.verifyMse(roiImgData, self.movieStruct.mask,...
                               thresh);
        end

        function verifyMse(self, img1, img2, thresh)
            err = immse(img1, img2);
            self.verifyLessThanOrEqual(err, thresh);
        end
    end
end

