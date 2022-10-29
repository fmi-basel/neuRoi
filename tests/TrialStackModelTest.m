classdef TrialStackModelTest < matlab.unittest.TestCase
    % Tests the TrialModel class
    properties
        stackModel
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
            
            nTrial = 3;
            affineMats = {};
            affineMats{1} = [1 0 0; 0 1 0; -5 8 1];
            affineMats{2} = [1 0 0; 0 1 0; 10 -20 1];
            movieStructList = createTestMovies(affineMats{1}, affineMats{2});
            anatomyStack = cellfun(@(x) x.anatomy, movieStructList, 'UniformOutput', false);
            responseStack = anatomyStack;
            
            roiArrStack = cellfun(@(x) roiFunc.RoiArray('maskImg', x.mask),...
                                  movieStructList, 'UniformOutput', false);

            trialNameList = arrayfun(@(x) sprintf('trial%02d', x), 1:nTrial,...
                                              'UniformOutput', false);

            imageSize = size(movieStructList{1}.anatomy);
            transfomrStack = {};
            for k=1:2
                transformStack{k} = createTransform(imageSize, affineMats{k}(3, 1:2));
            end

            transfomrInvStack = {};
            for k=1:2
                transformInvStack{k} = createTransform(imageSize, -affineMats{k}(3, 1:2));
            end

            templateIdx = 1;
            testCase.stackModel = trialStack.TrialStackModel(trialNameList,...
                                                             anatomyStack,...
                                                             responseStack,...
                                                             'roiArrStack', roiArrStack,...
                                                             'transformStack', transformStack,...
                                                             'transformInvStack', transformInvStack,...
                                                             'templateIdx', templateIdx,...
                                                             'doSummarizeRoiTags', true);
        end
    end

    methods(Test)
        function testRoi(testCase)
            stackModel = testCase.stackModel;
            
            stackModel.selectTrial(1);
            position = [65,45; 65,46; 66,45; 66,46];
            roi = roiFunc.RoiM(position);
            stackModel.addRoi(roi);
            stackModel.deleteRoi(3);
            
            stackModel.selectTrial(2);
            position = [61,41; 62,41; 62,42; 63,42];
            roi = roiFunc.RoiM(position);
            stackModel.addRoi(roi);
            
            position = [64,43; 64,44; 65,43; 65,44];
            roi = roiFunc.RoiM(position);
            stackModel.addRoi(roi);
            
            position = [40,90; 40,91; 42,90; 42,91];
            freshRoi = roiFunc.RoiM(position);
            stackModel.updateRoi(3, freshRoi);
            stackModel.deleteRoiInStack(2);
            
            stackModel.selectTrial(3);
            position = [55,82; 56,82; 55,83; 56,83];
            freshRoi = roiFunc.RoiM(position);
            stackModel.updateRoi(1, freshRoi);
            
            stackModel.selectTrial(2);
            % select in arr 2, roi #6 and #7
            stackModel.selectRois([2, 2], [6, 7]);
            stackModel.addRoisInStack();
  
            % Verify
            % trial 1
            % has roi 1, 4, 5, 6
            % trial 2
            % has roi 1, 3, 4, 6
            % updated roi 3
            % trial 3
            % has roi 1, 3, 4, 6
            % updated roi 1
            % TODO set unique tag when adding ROIs in different trials    
            % TODO then gui should be built for a group a roiArr, 1 for common and 1 for diff
        end
        
        % add/update/delete ROI in current trial
        % apply ROI add/delete to trial stack
        
    end
end


function movieStructList = createTestMovies(affineMat2, affineMat3)
    movieStructList = {};
    movieStructList{1} = createMovie();
    movieStructList{2}= createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    movieStructList{3}= createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end

function transf = createTransform(imageSize, offsetYx)
    transf.xcorr = repmat((1:imageSize(2)) + offsetYx(1), [imageSize(1), 1]);
    transf.ycorr = repmat((1:imageSize(1)) + offsetYx(2), [imageSize(2), 1]);
    transf.width = imageSize(2);
    transf.height = imageSize(1);
end
