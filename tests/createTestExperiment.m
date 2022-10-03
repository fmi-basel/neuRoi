function expStruct = createTestExperiment(tmpExpDir)
    if ~exist(tmpExpDir, 'dir')
        error('Temporary experiment directory does not exist!')
    end
    trialStructList = {};
    trialStructList{1} = createTestMovie();
    affineMat2 = [1 0 0; 0 1 0; -3 2 1];
    trialStructList{2}= createTestMovie('ampList', [2, 2, 3], 'affineMat', affineMat2);
    affineMat3 = [1.2 0 0; 0.33 1 0; 2 3 1];
    trialStructList{3}= createTestMovie('ampList', [2, 2, 3], 'affineMat', affineMat3);
    nTrial = length(trialStructList);

    % Save trial movie
    for k=1:nTrial
        saveMovie(trialStructList{k}.rawMovie,...
                  fullfile(tmpExpDir, sprintf('trial%02d.tif', k)));
    end

    rawFileList = arrayfun(@(x)(sprintf('trial%02d', x)), 1:nTrial, 'UniformOutput', false);
    resultDir = fullfile(tmpExpDir, 'result');
    expInfo.name = 'test-experiment';
    expInfo.frameRate = 5;
    expInfo.nPlane = 1;
    expInfo.mapSize = [20, 24];


    % Initiate experiment
    myexp = NrModel('rawDataDir', tmpExpDir,...
                    'rawFileList', rawFileList,...
                    'resultDir',resultDir,...
                    'expInfo',expInfo);
    expStruct.myexp = myexp;
    expStruct.trialStructList = trialStructList;
end

function saveMovie(rawMovie, filePath)
    movieFunc.saveTiff(uint8(rawMovie), filePath);
end
