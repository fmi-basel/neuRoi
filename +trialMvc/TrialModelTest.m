classdef TrialModelTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        trial
        anatomy
        timeTraceMat
        tmpDir
    end
       
    methods(TestMethodSetup)
        function createTrial(testCase)
            tmpDir = 'tmp';
            if ~exist(tmpDir, 'dir')
                mkdir(tmpDir)
            end

            movieSize = [12, 10, 20];
            mockMovie.name = 'mock_movie';
            mockMovie.meta = struct('width', movieSize(1),...
                                    'height', movieSize(2),...
                                    'totalNFrame', movieSize(3));
            rawMovie = zeros(movieSize);
            roiList = {[3,3;3,4;3,5;4,3;4,4;4,5;5,3;5,4;5,5]
                                [5,8;5,9;6,8;6,9;7,8;7,9;6,7],
                                [9,6;9,7;10,6;10,7;11,6]
                               };
            startList = [6, 4, 8];
            durList = [3, 4, 4];
            baseList = [1, 3, 4];
            ampList = [10, 9, 2];
            
            timeTraceMat = zeros(length(roiList), movieSize(3));
            for k=1:length(roiList)
                roi=roiList{k};
                start = startList(k);
                dur = durList(k);
                base = baseList(k);
                amp = ampList(k);
                mask=zeros(movieSize(1:2));
                mask(sub2ind(movieSize(1:2),roi(:,1), roi(:,2))) = 1;
                dynamic = computeDynamic(mask, start, dur, base, amp, movieSize);
                rawMovie = rawMovie + dynamic;
                timeTrace = computeTimeTrace(start, dur, base, amp, movieSize(3));
                timeTraceMat(k, :) = timeTrace;
            end
            mockMovie.rawMovie = rawMovie;
            testCase.trial = trialMvc.TrialModel('mockMovie', mockMovie);
            testCase.anatomy = mean(rawMovie, 3);
            testCase.timeTraceMat = timeTraceMat;
            testCase.addTeardown(@delete, testCase.trial)
            
            function timeTrace = computeTimeTrace(start, dur, base, amp, totalT)
                timeTrace =  base * ones(1, totalT);
                timeTrace(start:start+dur-1) = amp;
            end
            
            function dynamic = computeDynamic(mask, start, dur, base, amp, movieSize)
                dynamic = zeros(movieSize);
                dynamic = base * repmat(mask, 1, 1, movieSize(3));
                dynamic(:, :, start:start+dur-1) = amp * repmat(mask, 1, 1, dur);
            end
            
            testCase.tmpDir = tmpDir;
            testCase.addTeardown(@rmdir, tmpDir, 's')
        end
    end

    methods(Test)
        function testCalcAnatomy (testCase)
            [mapData, mapOption] = testCase.trial.calcAnatomy();
            testCase.verifyEqual(mapData, testCase.anatomy);
        end
        
        % function testExtraceTimeTrace(testCase)
        %     % TODO make this RoiM
        %     position = [3,3; 3,6; 6,3; 6,6];
        %     freshRoi = RoiFreehand(position);
        %     testCase.trial.addRoi(freshRoi);
        %     [timeTraceMat, roiArray] = testCase.trial.extractTimeTraceMat();
        %     roiIdx = 1;
        %     timeTrace = timeTraceMat(roiIdx, :);
        %     testCase.verifyEqual(timeTrace, testCase.timeTraceMat(roiIdx, :));
        % end
        
        function filePath = createRoiFreehandArrFile(testCase)
            roiArray = createRoiFreehandArr();
            filePath = fullfile(testCase.tmpDir, 'RoiFreehandArr.mat');
            save(filePath, 'roiArray')
        end
        
        function testLoadRoiFreehandArr(testCase)
            filePath = testCase.createRoiFreehandArrFile();
            imageSize = size(testCase.anatomy);
            
            testCase.trial.loadRoiArr(filePath);
            testCase.verifyEqual(class(testCase.trial.roiArr), 'roiFunc.RoiArray')
        end
                
    end

end


function roiArray = createRoiFreehandArr()
    positionList = {[3,3; 3,6; 6,6; 6,3], [2,7; 4,7; 4,10; 2,10]};
    roiArray = RoiFreehand.empty();
    for k=1:length(positionList)
        roiFh = RoiFreehand(positionList{k});
        roiFh.tag = k;
        roiArray(k) = roiFh;
    end
end

