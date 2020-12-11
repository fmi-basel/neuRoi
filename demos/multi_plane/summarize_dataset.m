%% Add path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Load experiment configuration from file
expName = '2020-01-15-longPulse';
expSubDir = fullfile(expName,'OB');
expFilePath = sprintf(['/home/hubo/Projects/Ca_imaging/results/%s/' ...
                    'experimentConfig_%s.mat'],expSubDir,expName);
foo = load(expFilePath);
myexp = foo.myexp;
%% Get trial table
trialTable = batch.getTrialTable(myexp.rawFileList,myexp.expInfo.odorList);
% [table((1:height(trialTable))'),trialTable]
% deleteTidx = [4, 11,19];
% trialTable(deleteTidx,:) = [];
trialTable = batch.addTrialNum(trialTable);
deleteTidx = trialTable.trialNum > 3;
trialTable(deleteTidx,:) = [];
%% Anatomy maps
planeList = 1:4;
tt = trialTable(trialTable.trialNum==1,:);
anatomyPrefix = myexp.anatomyConfig.filePrefix;
anatomyDir = myexp.getDefaultDir('anatomy');
rawFile = trialTable.FileName(1);
rawFile = rawFile{:};
for planeNum=planeList
    planeString = NrModel.getPlaneString(planeNum);
    anatomySubDir = fullfile(anatomyDir,planeString);
    anaMapArray{planeNum} = movieFunc.readTiff(fullfile(anatomySubDir,[anatomyPrefix,rawFile]));
end

figWidth = 700;
figHeight = 700;
figure('InnerPosition',[200 500 figWidth figHeight]);
climit = [0 100];
for k=1:4
    subplot(2,2,k)
    imagesc(anaMapArray{k})
    colormap(gray)
    ax = gca;
    ax.Visible='off';
    caxis(climit)
end
anatomyFile = 'anatomy.pdf'
saveas(gcf, anatomyFile)

%% Alignment between trials

%% Response maps
responseMapFilePath = {};
for planeNum=planeList
    responseDir = fullfile(myexp.resultDir, 'response_map');
    responseMapFileName = sprintf('responseMap_plane%d.pdf', ...
                                  planeNum);
    responseMapFilePath{planeNum} = fullfile(responseDir,responseMapFileName);
end
%% Time trace
planeList = [1 2 3];
timeTraceDir = fullfile(myexp.resultDir, 'time_trace');
for planeNum=planeList
planeString = NrModel.getPlaneString(planeNum);
traceResultDir = fullfile(myexp.resultDir,'time_trace', ...
                          planeString);
timeTraceDataFilePath = fullfile(traceResultDir, ...
                           'timetrace.mat');
foo = load(timeTraceDataFilePath);
timeTraceMatList = foo.timeTraceMatList;
cutFrameNum = 50;
timeTraceMatList = cellfun(@(x) x(:,cutFrameNum+1:end), timeTraceMatList,...
                           'UniformOutput',false);

sm = 0;
trialTable2 = trialTable;
trialTable2.fileIdx = (1:21)'
batch.plotMaps(timeTraceMatList,trialTable2,[],clut2b,sm)

    ttFileName = sprintf('time_trace_plane%d.pdf', ...
                                  planeNum);
    ttFilePath{planeNum} = fullfile(timeTraceDir,ttFileName);
h = gcf;
set(h,'PaperPositionMode','auto');         
set(h,'PaperOrientation','landscape');
print(gcf, '-dpdf', ttFilePath{planeNum}, '-bestfit')
% saveas(gcf,ttFilePath{planeNum});
end

%% Put all figure into one file
addpath('../../../neuRoi/export_fig')
summaryFile = 'summary.pdf'
append_pdfs(summaryFile, anatomyFile, responseMapFilePath{:},ttFilePath{:})


