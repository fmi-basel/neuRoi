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
            
            roiArrStack = testCase.splitRoiArrStack(roiArrStack);

            trialNameList = arrayfun(@(x) sprintf('trial%02d', x), 1:nTrial,...
                                              'UniformOutput', false);

            imageSize = size(movieStructList{1}.anatomy);
            transformStack = {};
            transformStack{1} = BUnwarpJ.Transformation('identity');
            for k=2:3
                transformStack{k} = createTransform(imageSize, affineMats{k-1}(3, 1:2));
            end

            transfomrInvStack = {};
            transformInvStack{1} = BUnwarpJ.Transformation('identity');
            for k=2:3
                transformInvStack{k} = createTransform(imageSize, -affineMats{k-1}(3, 1:2));
            end

            % TODO
            % identity transformation
            % class for transformation
            templateIdx = 1;
            testCase.stackModel = trialStack.TrialStackModel(trialNameList,...
                                                             anatomyStack,...
                                                             responseStack,...
                                                             'roiArrStack', roiArrStack,...
                                                             'transformStack', transformStack,...
                                                             'transformInvStack', transformInvStack,...
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
            
            % TODO if I already deleted #3 in trial 1, and then delete #3 from the stack from trial 2, problem?
            stackModel.deleteRoiInStack(3);
            
            stackModel.selectTrial(3);
            position = [55,82; 56,82; 55,83; 56,83];
            freshRoi = roiFunc.RoiM(position);
            stackModel.updateRoi(1, freshRoi);
            
            stackModel.selectTrial(2);
            % select in arr 2, roi #6 and #7
            stackModel.selectRois([2], {[6, 7]});
            stackModel.addRoisInStack();
  
            % Verify
            % trial 1
            tags = testCase.getTags(1, 1);
            testCase.verifyEqual(tags, [1, 4, 6, 7]);
            tags = testCase.getTags(1, 2);
            testCase.verifyEqual(tags, [5]);

            % trial 2
            tags = testCase.getTags(2, 1);
            testCase.verifyEqual(tags, [1, 4, 6, 7]);
            tags = testCase.getTags(2, 2);
            testCase.verifyEqual(length(tags), 0);
            % updated roi 3

            % trial 3
            tags = testCase.getTags(3, 1);
            testCase.verifyEqual(tags, [1, 4, 6, 7]);
            tags = testCase.getTags(3, 2);
            testCase.verifyEqual(length(tags), 0);
            % updated roi 1
        end
    end
    
    methods
        function tags = getTags(testCase, trialIdx, roiArrIdx)
            tags = testCase.stackModel.roiCollectStack{trialIdx}.roiArrList(roiArrIdx).getTagList();
        end

        function troiArrStack = splitRoiArrStack(testCase, roiArrStack)
            troiArrStack = {};
            for k=1:length(roiArrStack)
                troiArrStack{k} = testCase.splitRoiArr(roiArrStack{k});
            end
        end
        
        function roiArr = splitRoiArr(testCase, roiArr)
            tags1 = [1, 2];
            tags2 = [3, 4];
            roiArr.addGroup('region1');
            roiArr.addGroup('region2');
            roiArr.setRoiGroup(tags1, 'region1');
            roiArr.setRoiGroup(tags2, 'region2');
        end
    end
end


function movieStructList = createTestMovies(affineMat2, affineMat3)
    movieStructList = {};
    movieStructList{1} = createMovie();
    movieStructList{2}= createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    movieStructList{3}= createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end

function transf = createTransform(imageSize, offsetYx)
    xcorr = repmat((1:imageSize(2)) + offsetYx(1), [imageSize(1), 1]);
    ycorr = repmat((1:imageSize(1)) + offsetYx(2), [imageSize(2), 1]);
    transf = BUnwarpJ.Transformation('bunwarpj', xcorr, ycorr', imageSize);
end
