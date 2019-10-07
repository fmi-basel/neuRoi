%% Add neuRoi rood directory to path
addpath('../../neuRoi')
%% Clear variables
clear all
foo = load('../../neuRoi/colormap/clut2b.mat');
clut2b = foo.clut2b;
%% Step01a Configure experiment and image processing parameters
%% Step01b Load experiment configuration from file
expName = '2019-09-25-fastZOB';
expFilePath = sprintf(['/home/hubo/Projects/Ca_imaging/results/%s/' ...
                    'experimentConfig_%s.mat'],expName,expName);
foo = load(expFilePath);
myexp = foo.myexp;
% myexp.odorList =  {'ala','trp','ser','tca','gca','tdca','acsf','spont'};
disp(myexp.expInfo)
%% Step03 Open neuRoi GUI
% mycon = NrController(myexp);

%% dF/F maps for all trials
planeNum = 2;
inFileType = 'binned';
mapType = 'response';
mapOption1 = struct('offset',-10,...
                    'fZeroWindow',[10 12],...
                    'responseWindow',[14 21]);

startPointList = [0 0 0 0 0 0 0 0]% [79 95 85 95 95 95 95 95];
odorDelayList = startPointList - min(startPointList)

saveMap = false;
trialOption = [];
fileIdx = 1:24;
[responseArray,trialTable] = myexp.calcMapBatch(inFileType,...
                                   mapType,mapOption1,...
                                   'trialOption',trialOption,...
                                   'odorDelayList',odorDelayList,...
                                   'sortBy','odor',...
                                   'planeNum',planeNum,...
                                    'fileIdx',fileIdx);
% TODO filtering of response maps
%% Plot dF/F maps
nTrialPerOdor = 3;
climit = [0 1.1];
sm = 3;
batch.plotMaps(responseArray,trialTable, ...
               nTrialPerOdor,climit,clut2b,sm)
%% Save dF/F map
responseDir = fullfile(myexp.resultDir, 'responseMap');
if ~exist(responseDir, 'dir')
    mkdir(responseDir)
end
responseMapFileName = sprintf('responseMap_plane%d.pdf',planeNum);
responseMapFilePath = fullfile(responseDir,responseMapFileName);
                               
saveas(gcf,responseMapFilePath)

