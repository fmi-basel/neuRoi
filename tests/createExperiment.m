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
