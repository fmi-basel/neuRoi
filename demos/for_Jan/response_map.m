%% Add neuRoi rood directory to path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Load colormap
foo = load('../../../neuRoi/colormap/clut2b.mat');
clut2b = foo.clut2b;
%% Step01a Configure experiment and image processing parameters
%% Step01b Load experiment configuration from file
expName = '2020-01-15-longPulse';
expSubDir = fullfile(expName,'OB');
expFilePath = sprintf(['/home/hubo/Projects/Ca_imaging/results/%s/' ...
                    'experimentConfig_%s.mat'],expSubDir,expName);
foo = load(expFilePath);
myexp = foo.myexp;
myexp.expInfo.odorList =  {'ala','trp','ser','tca','gca','tdca','acsf','spont'};
disp(myexp.expInfo)
%% Step03 Open neuRoi GUI
% mycon = NrController(myexp);
%% Get trial table
trialTable = batch.getTrialTable(myexp.rawFileList,myexp.expInfo.odorList);
% [table((1:height(trialTable))'),trialTable]
deleteTidx = [4, 11,19];
trialTable(deleteTidx,:) = [];
trialTable = batch.addTrialNum(trialTable);
%% Sort file index
% for k=1:length(myexp.rawFileList);x = myexp.rawFileList{k}; fprintf('%s\t%d\n',x,k);end
fileIdx = trialTable.fileIdx;

%% dF/F maps for all trials
planeNum = 4;
inFileType = 'binned';
mapType = 'response';
mapOption1 = struct('offset',-10,...
                    'fZeroWindow',[10 12],...
                    'responseWindow',[18 22]);
% mapOption2 = struct('offset',-10,...
%                     'fZeroWindow',[32 34 ],...
%                     'responseWindow',[12 14]);

% startPointList = [0 0 0 0 0 0 0 0]% [79 95 85 95 95 95 95 95];
% odorDelayList = startPointList - min(startPointList)

trialOption = [];
responseArray = myexp.calcMapBatch(inFileType,...
                                   mapType,mapOption1,...
                                   'trialOption',trialOption,...
                                   'planeNum',planeNum,...
                                   'fileIdx',fileIdx);
%                                   'odorDelayList',odorDelayList,...

% Save MAT file
responseDir = fullfile(myexp.resultDir, 'response_map');
responseMapFileName = sprintf('responseMap_plane%d.mat',planeNum);
responseMapFilePath = fullfile(responseDir,responseMapFileName);
save(responseMapFilePath,'responseArray','trialTable')
%% Plot dF/F maps
climit = [0 1];
sm = 3;
% responseArray = cat(3,responseArray2(:,:,1),responseArray1(:,:,1:2),...
%                     responseArray2(:,:,2),responseArray1(:,:,3:end));
% trialTable = [trialTable2(1,:);trialTable1(1:2,:);trialTable2(2,:);trialTable1(3:end,:)];
batch.plotMaps(responseArray,trialTable,climit,clut2b,sm)
%% Save dF/F map
responseDir = fullfile(myexp.resultDir, 'response_map');
if ~exist(responseDir, 'dir')
    mkdir(responseDir)
end
responseMapFileName = sprintf('responseMap_plane%d.pdf',planeNum);
% responseMapFileName = sprintf('responseMap_plane%d.fig',planeNum);
responseMapFilePath = fullfile(responseDir,responseMapFileName);
                               
saveas(gcf,responseMapFilePath)

