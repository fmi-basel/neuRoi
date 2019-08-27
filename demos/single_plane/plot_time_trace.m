%% Add path
addpath('../../neuRoi');
%% Clear variabless
clear all
%% Close figure
close all
%% File Paths
dataDir = '/media/hubo/Bo_FMI/Data/two_photon_imaging/';
resultDir = '/home/hubo/Projects/Ca_imaging/results/';
subDir = '2018-09-04-EM';
traceResultDir = fullfile(resultDir,subDir,'timeTrace');
fileNameArray={'BH18_41dpf_f1_z75_s1_o1ala_002_.tif',...
               'BH18_41dpf_f1_z75_s1_o2trp_001_.tif',...
               'BH18_41dpf_f1_z75_s1_o3ser_001_.tif',...
               'BH18_41dpf_f1_z75_s1_o4acsf_001_.tif',...
               'BH18_41dpf_f1_z75_s1_o5food_001_.tif',...
               'BH18_41dpf_f1_z75_s1_o6spont_001_.tif',...
               'BH18_41dpf_f1_z75_s2_o1trp_001_.tif',...
               'BH18_41dpf_f1_z75_s2_o2acsf_001_.tif',...
               'BH18_41dpf_f1_z75_s2_o3ala_001_.tif',...
               'BH18_41dpf_f1_z75_s2_o4ser_001_.tif',...
               'BH18_41dpf_f1_z75_s2_o5food_001_.tif',...
               'BH18_41dpf_f1_z75_s2_o6spont_001_.tif',...
               'BH18_41dpf_f1_z75_s3_o1acsf_001_.tif',...
               'BH18_41dpf_f1_z75_s3_o2ser_001_.tif',...
               'BH18_41dpf_f1_z75_s3_o3ala_001_.tif',...
               'BH18_41dpf_f1_z75_s3_o4trp_001_.tif',...
               'BH18_41dpf_f1_z75_s3_o5food_001_.tif',...
               'BH18_41dpf_f1_z75_s3_o6spont_001_.tif'};
%% Sort file names by odor
nTrialPerOdor = 3;
odorList = {'ala','trp','ser','food','acsf','spont'};
fileNameArraySorted = shortcut.sortFileNameArray(fileNameArray,'odor',odorList);
filePathArray = cellfun(@(x) fullfile(dataDir,subDir,x), ...
                        fileNameArraySorted,'UniformOutput',false);

%% Load time trace matrices
timeTraceMatArray = {};
for k=1:length(filePathArray)
    filePath = filePathArray{k};
    timeTraceFilePath = shortcut.getTimeTraceFilePath(filePath, ...
                                                      traceResultDir);
    foo = load(timeTraceFilePath);
    timeTraceMatArray{k} = foo.timeTraceMat;
end

%% Plot heat map
zlim = [0 18];
nCol = length(odorList)+1;
nRow = nTrialPerOdor;
nSubplot = length(timeTraceMatArray);
indMat = reshape(1:nRow*nCol,nCol,nRow).';

figWidth = 1800;
figHeight = 300*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
for k=1:nSubplot
    subplot(nRow,nCol,indMat(k))
    imagesc(timeTraceMatArray{k})
    % ax.Visible = 'off';
    if mod(k,nRow) == 1
        ax = gca;
        odor = shortcut.getOdorFromFileName(filePathArray{k});
        title(odor);
        set(get(ax,'Title'),'Visible','on');
    end
    caxis(zlim)
end
subplot(nRow,nCol,indMat(nSubplot+1))
caxis(zlim)
colorbar('Location','west')
axis off

%% Save heat map
heatMapFilePath = fullfile(traceResultDir, ...
                           'time_trace_heatmap.svg');
saveas(fig,heatMapFilePath)


%% Calculate average time trace for each odor
timeTraceAvgArray = shortcut.calcTimeTraceAvg(timeTraceMatArray,nTrialPerOdor);

%% Plot average time trace
frameRate = 30;
tvec = (1:size(timeTraceAvgArray{1},2))/frameRate;
nOdor = length(timeTraceAvgArray);
fig = figure;
axArray = gobjects(1,nOdor);
yLimit = [0 15];
for k=1:nOdor
    subplot(nOdor,1,k)
    axArray(k) = gca;
    plot(timeTraceAvgArray{k})
    %boundedline(tvec,timeTraceAvgArray{k},timeTraceSemArray{k})
    % errorbar(tvec,timeTraceAvgArray{k},timeTraceSemArray{k})
    ylim(yLimit)
    if k<nOdor
        set(gca,'XTick',[]);
    end
    odor = odorList(k);
    ylabel(odor)
end
linkaxes(axArray,'xy')
xlabel('Time (s)')

%% Save average time trace
timeTraceAvgFilePath = fullfile(traceResultDir, ...
                           'time_trace_avg.svg');
saveas(fig,timeTraceAvgFilePath)

%% Find peak time point in average time trace
peakArray = zeros(1,nOdor);
for k=1:nOdor
    tt = timeTraceAvgArray{k};
    peakArray(k) = find(tt==max(tt(:)));
end
peakArray
peakArray - min(peakArray)

%% Manually find response start points
startPointArray = [387,366,268,397,331,1000];
frameOffsetArray = startPointArray - min(startPointArray)
