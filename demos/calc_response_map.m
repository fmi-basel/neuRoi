%% Add neuRoi rood directory to path
addpath('../')
%% Clear variables
clear all
%% Step01a Configure experiment and image processing parameters
%% Step01b Load experiment configuration from file
expFilePath = '/home/hubo/Projects/Ca_imaging/results/2019-03-15-OBDp/experimentConfig_2019-03-15-OBDp.mat';
foo = load(expFilePath);
myexp = foo.myexp;
disp(myexp.expInfo)
%% dF/F maps for all trials
responseDir = myexp.getDefaultDir('response_map');
if ~exist(responseDir,'dir')
    mkdir(responseDir)
end

inFileType = 'binned';
mapType = 'response';
mapOption = struct('offset',-30,...
                   'fZeroWindow',[1 5],...
                   'responseWindow',[11 16]);
startPointList = [398 372 345 369]/30;
odorDelayList = startPointList - min(startPointList)

if strcmp(inFileType,'raw')
    inDir = myexp.rawDataDir;
    inFileList = myexp.rawFileList;
    frameRate = myexp.expInfo.frameRate;
    trialOption = {'frameRate',frameRate,'process',true, ...
                   'noSignalWindow',[1 12]};
elseif strcmp(inFileType,'binned')
    inDir = myexp.binConfig.outDir;
    inFileList = myexp.getFileList('binned');
    shrinkZ = myexp.binConfig.param.shrinkFactors(3);
    frameRate = myexp.expInfo.frameRate/shrinkZ;
    trialOption = {'frameRate',frameRate};
end

odorList = myexp.expInfo.odorList;
sortedFileTable = batch.sortFileNameByOdor(inFileList,odorList);
trialTable = batch.getWindowDelayTable(sortedFileTable,odorList,odorDelayList);

% outDir = responseDir;
% outFileType = 'mat';
outDir = [];
outFileType = 'mat';

responseArray = batch.calcMapFromFile(inDir,trialTable.FileName,...
                                      'response',...
                                      'mapOption',mapOption,...
                                      'windowDelayList',trialTable.Delay,...
                                      'trialOption',trialOption,...
                                      'outDir',outDir,...
                                      'outFileType',outFileType);

%% Plot dF/F maps
nTrialPerOdor = 3;
climit = [0 0.2];
batch.plotMaps(responseArray,trialTable,nTrialPerOdor,climit)
