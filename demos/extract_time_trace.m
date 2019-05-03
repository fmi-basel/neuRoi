%% Add neuRoi rood directory to path
addpath('../')
%% Clear variables
clear all
%% Step01a Configure experiment and image processing parameters
%% Step01b Load experiment configuration from file
expFilePath = '/home/hubo/Projects/Ca_imaging/results/2019-03-15-OBDp/experimentConfig_2019-03-15-OBDp.mat';
foo = load(expFilePath);
myexp = foo.myexp;
%% Step02 (optional) Sepcify options for opening a trial
myexp.roiDir = myexp.getDefaultDir('roi');
myexp.loadFileType = 'binned';
myexp.trialOptionRaw = struct('process',true,...
                              'noSignalWindow',[1 12],...
                              'intensityOffset',-30);
myexp.trialOptionBinned = struct('process',false,...
                                 'noSignalWindow',[],...
                                 'intensityOffset',100);

myexp.responseOption = struct('offset',100,...
                        'fZeroWindow',[1 5],...
                        'responseWindow',[15 20]);
myexp.responseMaxOption = struct('offset',100,...
                           'fZeroWindow',[1 5],...
                           'slidingWindowSize',3);
myexp.mapsAfterLoading = {'response','responseMax'};

myexp.alignToTemplate = true;
% trial = myexp.loadTrialFromList(1,'binned')
%% Step03 Open neuRoi GUI
mycon = NrController(myexp);
