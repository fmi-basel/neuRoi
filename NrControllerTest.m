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
            roiArray = roiFunc.RoiArray('maskImg', templateMask);
            roiDir = myexp.getDefaultDir('roi');
            if ~exist(roiDir, 'dir')
                mkdir(roiDir)
            end
            save(roiFile, 'roiArray')

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
            myexp.processRawData();
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
            
            mycon.BUnwarpJCalculateButton_Callback();
            
            myexp.applyBunwarpj();
            mycon.BUnwarpJInspectTrialsButton_Callback();
            % myexp.inspectStack();


            % prefix = '';
            % bunwarpjDir = fullfile(testCase.dirs.resultDir, 'bunwarpj', 'transf');
            % tFileList = cellfun(@(x) fullfile(bunwarpjDir, 'Transformations',...
            %                                   iopath.modifyFileName(x,prefix,'_transformation','txt')),...
            %                     myexp.rawFileList(2:end),...
            %                     'UniformOutput', false);
            % rtFileList = cellfun(@(x) fullfile(bunwarpjDir, 'TransformationsRaw',...
            %                                    iopath.modifyFileName(x,prefix,'_transformationRaw','txt')),...
            %                      myexp.rawFileList(2:end),...
            %                      'UniformOutput', false);
            % filesExist = cellfun(@(x) exist(x, 'file'), [tFileList, rtFileList]);
            % testCase.verifyTrue(all(filesExist));
            
            % myexp.applyBunwarpj();
            % foo = load(fullfile(bunwarpjDir,"roiArrayStack.mat"));
            % roiArrayStack = foo.roiArrayStack;
            % for k=1:3
            %     err = mean(mean(abs(roiArrayStack(k).convertToMask()-testCase.movieStructList{k}.mask)));
            %     testCase.verifyLessThanOrEqual(err, 0.05)
            % end

            % myexp.inspectStack();
            % Verify trialStack
        end
        
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