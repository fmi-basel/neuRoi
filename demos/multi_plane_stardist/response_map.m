%% Add neuRoi to path
addpath('../../neuRoi')
%% Clear variables
clear all
%% Load colormap
foo = load('../../neuRoi/colormap/clut2b.mat');
clut2b = foo.clut2b;
%% Step01b Load experiment configuration from file
expName = '2021-09-02-DpOBEM-JH18';
expSubDir = fullfile(expName,'Dp');
expFilePath = sprintf(['/home/hubo/Projects/Ca_imaging/results/%s/' ...
                    'experiment_%s.mat'],expSubDir,expName);
foo = load(expFilePath);
myexp = foo.self;
% myexp.expInfo.odorList =  {'phe','trp','arg','tca','gca','tdca','acsf','spont'};
disp(myexp.expInfo)
%% Get trial table
myexp.arrangeTrialTable()
%% Remove extra trials
removeIdx = [30,2,31,4,3,1,5,32]; % 09-02-Dp
myexp.removeTrialFromTable(removeIdx);
myexp.trialTable.trialNum = [];
myexp.trialTable = batch.addTrialNum(myexp.trialTable);
%% dF/F maps for all trials

fileIdx = myexp.trialTable.fileIdx;
planeNum = 1;
inFileType = 'raw';
mapType = 'response';
mapOption1 = struct('offset',-10,...
                    'fZeroWindow',[12 14],...
                    'responseWindow',[17 22]);
startPointList = [0 0 0 0 0 0 0 0]% [79 95 85 95 95 95 95 95];
odorDelayList = startPointList - min(startPointList)
saveMap = false;
trialOption = [];
responseArray= myexp.calcMapBatch(inFileType,...
                                   mapType,mapOption1,...
                                   'trialOption',trialOption,...
                                   'odorDelayList',odorDelayList,...
                                   'sortBy','odor',...
                                   'planeNum',planeNum,...
                                    'fileIdx',fileIdx);
%% Plot dF/F maps
climit = [-0.01 0.03];
sm = 3;
batch.plotMaps(responseArray,myexp.trialTable, ...
               climit,clut2b,sm)
%% Save dF/F map
responseDir = fullfile(myexp.resultDir, 'response_map');
if ~exist(responseDir, 'dir')
    mkdir(responseDir)
end
responseMapFileName = sprintf('responseMap_plane%d.svg',planeNum);
% responseMapFileName = sprintf('responseMap_plane%d.fig',planeNum);
responseMapFilePath = fullfile(responseDir,responseMapFileName);
                               
saveas(gcf,responseMapFilePath)

