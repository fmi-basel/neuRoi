%% Add neuRoi rood directory to path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01a Configure experiment and image processing parameters
%% Step01b Load experiment configuration from file
expName = 'Nesibe-20190501-f1';
expFilePath = sprintf('/home/hubo/Projects/Ca_imaging/results/%s/experimentConfig_%s.mat',expName,expName);
foo = load(expFilePath);
myexp = foo.myexp;
disp(myexp.expInfo)
%% dF/F maps for all trials
inFileType = 'binned';
mapType = 'response';
mapOption = struct('offset',-30,...
                   'fZeroWindow',[1 5],...
                   'responseWindow',[10 15]);
% startPointList = [398 372 345 369]/30;
startPointList = [319 335 328 366 346 357 372 375]/30;
odorDelayList = startPointList - min(startPointList)

saveMap = false;
trialOption = [];
[responseArray,trialTable] = myexp.calcMapBatch(inFileType,...
                                   mapType,mapOption,...
                                   'trialOption',trialOption,...
                                   'odorDelayList',odorDelayList,...
                                   'sortBy','odor',...
                                   'saveMap',saveMap);
% TODO filtering of response maps
%% Plot dF/F maps
nTrialPerOdor = 3;
climit = [0 0.2];
idx = 1:24;
batch.plotMaps(responseArray(:,:,idx),trialTable(idx,:), ...
               nTrialPerOdor,climit)
%% Save dF/F map
responseDir = fullfile(myexp.resultDir, 'responseMap')
if ~exist(responseDir, 'dir')
    mkdir(responseDir)
end
responseMapFilePath = fullfile(responseDir, ...
                               'responseMap.svg');
saveas(gcf,responseMapFilePath)

