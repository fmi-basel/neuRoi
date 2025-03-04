classdef NrControllerTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        dirs
        movieStructList
        myexp
        mycon
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
            
            stack = testUtils.createStack();
            rawFileList = testUtils.saveTestMovies(tmpDir, stack.movieStructList);
            

            expInfo.name = 'test_exp';
            expInfo.frameRate = 10;
            expInfo.nPlane = 1;

            myexp = NrModel('rawDataDir', tmpDir,...
                            'rawFileList', rawFileList,...
                            'resultDir', resultDir,...
                            'expInfo', expInfo);
            mycon = NrController(myexp);

            templateMask = stack.movieStructList{1}.templateMask;
            maskDir = myexp.getDefaultDir('mask');
            if ~exist(maskDir, 'dir')
                mkdir(maskDir)
            end
            templateMaskFile = fullfile(maskDir, 'template_mask.tif');
            movieFunc.saveTiff(uint16(templateMask), templateMaskFile);
            
            % Convert template mask to RoiArray
            roiDir = myexp.getDefaultDir('roi');
            roiFile = fullfile(roiDir, iopath.modifyFileName(rawFileList{1}, '', '_RoiArray', 'mat'));
            roiArr = roiFunc.RoiArray('maskImg', templateMask);
            roiDir = myexp.getDefaultDir('roi');
            if ~exist(roiDir, 'dir')
                mkdir(roiDir)
            end
            save(roiFile, 'roiArr')

            myexp.processRawData();

            testDirs.tmpDir = tmpDir;
            testDirs.resultDir = resultDir;
            
            testCase.dirs = testDirs;
            testCase.movieStructList = stack.movieStructList;
            testCase.myexp = myexp;
            testCase.mycon = mycon;
            
            % testCase.addTeardown(@rmdir, tmpDir, 's')
        end
    end

    methods(Test)
        function testBunwarpj(testCase)
            myexp = testCase.myexp;
            mycon = testCase.mycon;
            src.Value = 1;
            mycon.BUnwarpJReferencetrial_Callback(src);
            
            src = struct('Value', true);
            mycon.BUnwarpJUseSIFT_Callback(src);
            
            src = struct('Value', false);
            mycon.BUnwarpJUseSIFT_Callback(src);
            
            evnt.NewValue.Tag = 'Norm_HistoEqu_radiobutton';
            mycon.BUnwarpJNormTypeGroup_Callback(1, evnt) % 1 is placeholder for src
            evnt.NewValue.Tag = 'Norm_CLAHE_radiobutton';
            mycon.BUnwarpJNormTypeGroup_Callback(1, evnt)
            % TODO make normalize image work
            evnt.NewValue.Tag = 'Norm_none_radiobutton';
            mycon.BUnwarpJNormTypeGroup_Callback(1, evnt)
            
            
            src = struct('String', 'transf1');
            mycon.BUnwarpJTransformationName_Callback(src);
            
            % button.Tag = 'Norm_CLAHE_radiobutton';
            % evnt.NewValue = button;
            % TODO also test hist eq
            % mycon.BUnwarpJNormTypeGroup_Callback(1, evnt)
            % mycon.BUnwarpJCalculateButton_Callback();
            
            % myexp.applyBunwarpj();
            myexp.calculatedTransformationsList = {'transf1'};
            myexp.calculatedTransformationsIdx = 1;
            
            myexp.BUnwarpJCalculated = true;
            mycon.BUnwarpJInspectTrialsButton_Callback();
            
            stackCtrl = mycon.stackCtrl;
            stackCtrl.view.setTrialNumberSlider(2);
            stackCtrl.TrialNumberSlider_Callback();
            
            
            % Add two ROIs
            import java.awt.Robot;
            import java.awt.event.*;
            mouse = Robot;
            roi1p = [556, 1537];
            pause(0.1);
            stackCtrl.addRoiByDrawing([73, 25; 84, 25; 84, 36; 73, 36]);
            stackCtrl.addRoiByDrawing([93, 85; 104, 85; 104, 96; 93, 96]);
            % Add the two ROIs in the stack
            mouse.mouseMove(roi1p(1)+187, roi1p(2)-8);
            mouse.keyPress(KeyEvent.VK_CONTROL);
            mouse.mousePress(InputEvent.BUTTON1_MASK); % actual left click press
            pause(0.1);
            mouse.mouseRelease(InputEvent.BUTTON1_MASK); 
            pause(0.1);
            mouse.keyRelease(KeyEvent.VK_CONTROL);
            stackCtrl.model.roiGroupName = 'default';
            stackCtrl.addRoisInStack();
        end

        % TODO test for multiplane data
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
