%% Add path
addpath('../../../neuRoi')
%% Clear variables
clear all
%% Step01 Load experiment configuration from file
rootPaths = load('../../../paths/rootPaths.mat');
expName = '2019-08-25-fastZ2';
expFileName = sprintf('experimentConfig_%s.mat',expName);
expFilePath = fullfile(rootPaths.projectDir,'results',expName,expFileName);
foo = load(expFilePath);
myexp = foo.myexp;
disp(myexp.expInfo)
%% Step02 (optional) Sepcify options for opening a trial
myexp.roiDir = myexp.getDefaultDir('roi');

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

myexp.alignToTemplate = true;
%% Step03 Open neuRoi GUI
mycon = NrController(myexp);
%% Change some parameters if you like
myexp.mapsAfterLoading = {};

%% Step04 Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROIs in each trial
% If you accidentally closed the GUI, the following code might
% throw an error. In that case, just run Step01, then continue with
% Step04

fileIdxList = [2 9];
planeNum = 1;
roiFileName = 'binned_x1y1z2_20190825_BH18_37dpf_OB_fastz_s2_o2tca_redo_001__RoiArray.mat';
planeString = NrModel.getPlaneString(planeNum);
roiFilePath = fullfile(myexp.roiDir,planeString,roiFileName);
roiFileList = repmat({roiFilePath},1,length(fileIdxList));
plotTrace = true;
myexp.extractTimeTraceBatch(fileIdxList, ...
                            roiFileList,planeNum, ...
                            plotTrace);
