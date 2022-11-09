%% Add path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Load experiment configuration from file
expFilePath = sprintf('/media/hubo/Bo_FMI/Chie_data/p1/results/experimentConfig_Chie-p1.mat');
foo = load(expFilePath);
myexp = foo.myexp;
disp(myexp.expInfo)
%% Step02 (optional) Sepcify options for opening a trial
myexp.roiDir = myexp.getDefaultDir('roi');
if ~exist(myexp.roiDir)
    mkdir(myexp.roiDir)
end
myexp.loadFileType = 'binned';
myexp.trialOptionRaw = struct('process',true,...
                              'noSignalWindow',[1 12],...
                              'intensityOffset',-30);
myexp.trialOptionBinned = struct('process',false,...
                                 'noSignalWindow',[],...
                                 'intensityOffset',-10);

myexp.responseOption = struct('offset',-10,...
                        'fZeroWindow',[1 5],...
                        'responseWindow',[15 20]);
myexp.responseMaxOption = struct('offset',-10,...
                           'fZeroWindow',[1 5],...
                           'slidingWindowSize',3);
% myexp.mapsAfterLoading = {'response','responseMax'};
myexp.mapsAfterLoading = {};

% myexp.alignToTemplate = true;
%% Step03 Open neuRoi GUI
mycon = NrController(myexp);
%% Change some parameters if you like
myexp.mapsAfterLoading = {};

%% Step04 Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROIs in each trial
% If you accidentally closed the GUI, the following code might
% throw an error. In that case, just run Step01, then continue with
% Step04

trialOption = struct('intensityOffset',-30,'process',true, ...
                     'noSignalWindow',[1 12]);
motionCorrDir = fullfile(myexp.rawDataDir,'motion_correction');
trialOption = struct('motionCorr',true,'motionCorrDir',motionCorrDir);

fileIdx = 2;

roiFileName = 'binned_x1y1z4_p1_99um_AA_001__RoiArray.mat';
roiFilePath = fullfile(myexp.roiDir,roiFileName);
sm = 0;
plotTrace = true;
myexp.extractTimeTraceMatBatch(trialOption,roiFilePath,fileIdx,sm, ...
                               plotTrace)


% TODO BIGBIG option for percentile, range for f0 calculation

%% Some simple plot to check the results
fileIdx = 2;
fileName = myexp.rawFileList{fileIdx};
[~,fileBaseName,~] = fileparts(fileName);
foo = load(['/media/hubo/Bo_FMI/Chie_data/p1/results/time_trace/' ...
            fileBaseName '_frame1toInfby1_traceResult.mat']);
timeTraceMat = foo.traceResult.timeTraceMat;
tvec = (1:length(timeTraceMat(1,:))) /30;

figure
hold
sm = 10;
for k=1:size(timeTraceMat,1)
    plot(tvec,smooth(timeTraceMat(k,:)))
end

