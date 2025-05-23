%% This script is a test for the trial stack feature
%% Add path
addpath('../../neuRoi/')
%% Load experiment configuration from file
clear all
expName = '2021-09-02-DpOBEM-JH18';
expSubDir =  fullfile(expName,'Dp');
if getenv('COMPUTERNAME')=='F462L-3B17DA' %JE Pc path to run the code
    expFilePath = sprintf(['C:/Data/eckhjan/test/%s/' ...
                        'experiment_%s.mat'],expSubDir,expName);
else
    expFilePath = sprintf(['/home/hubo/Projects/Ca_imaging/results/%s/' ...
                    'experiment_%s.mat'],expSubDir,expName);
end
foo = load(expFilePath);
myexp = foo.self;
myexp.expInfo.odorList =  {'phe','trp','arg','tdca','tca','gca','acsf','spont'};
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
planeNum = 3;
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
%% Load anatomy array
rawFileList = myexp.trialTable.FileName;
planeString = NrModel.getPlaneString(planeNum);
inDir = fullfile(myexp.resultDir,myexp.anatomyDir, ...
                 planeString);

anatomyPrefix = myexp.anatomyConfig.filePrefix;
anatomyFileList = iopath.modifyFileName(rawFileList, ...
                                        anatomyPrefix, ...
                                        '','tif');
anatomyArray = batch.loadStack(inDir,anatomyFileList);
%% Start trialStack GUI
stackModel = trialStack.TrialStackModel(rawFileList,...
                                        anatomyArray,...
                                        responseArray, roiArrays); 
stackCtrl = trialStack.TrialStackController(stackModel);
stackModel.contrastForAllTrial = true;
% Help for the gui (keyboard shortcut):
% j,k: go up and down in trial index
% q,w: change map type (q for anatomy, w for response)
%% Save responseArray
stackDir = myexp.getDefaultDir('trial_stack');
if ~exist(stackDir,'dir')
    mkdir(stackDir)
end
save(fullfile(stackDir,'stack.mat'),'stackModel')
%% Save responseArray
stackDir = myexp.getDefaultDir('trial_stack');
save(fullfile(stackDir,'responsesArray.mat'),'responseArray')
%% Load StackModel (if the stack.mat was previously saved)
stackDir = myexp.getDefaultDir('trial_stack');
foo = load(fullfile(stackDir,'stack.mat'));
stackModel = foo.stackModel;
stackCtrl = trialStack.TrialStackController(stackModel);
