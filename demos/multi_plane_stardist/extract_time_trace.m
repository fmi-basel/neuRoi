%% Add neuRoi to MATLAB path
addpath('../../../neuRoi')
%% Clear variables
clear all
close all force
% Step01 Load experiment configuration from file
rootPaths = load('../../../paths/rootPaths.mat'); % this file should be changed for different computers by simply change the path variable here
expName = '2021-07-31-DpOBEM-JH17';
regionName = 'Dp';
expSubDir = fullfile(expName,regionName);
expFileName = sprintf('experiment_%s.mat',expName);
expFilePath = fullfile(rootPaths.tungstenCaData, 'results_tmp',...
                       expSubDir,expFileName);

% load the experiment configuration as NrModel object
foo = load(expFilePath);
myexp = foo.self;
disp(myexp.expInfo)
% this is newly added for storing StarDist predicted masks
myexp.maskDir =  myexp.getDefaultDir('stardist_mask');
% Step02 (optional) Sepcify options for opening a trial
myexp.roiDir = myexp.getDefaultDir('roi');
myexp.loadFileType = 'raw';
myexp.trialOptionRaw = struct('process',true,...
                              'noSignalWindow',[1 6],...
                              'intensityOffset',-30);
myexp.localCorrelationOption = struct('tileSize', 16);
if strcmp(regionName, 'Dp')
    myexp.responseOption = struct('offset',-10,...
                                  'fZeroWindow',[12 15],...
                                  'responseWindow',[18 21]);

    myexp.responseMaxOption = struct('offset',-10,...
                                     'fZeroWindow',[12 15],...
                                     'slidingWindowSize',3);
else % if strcmp(regionName, 'OB')
    myexp.responseOption = struct('offset',-10,...
                                  'fZeroWindow',[12 15],...
                                  'responseWindow',[19 27]);
    myexp.responseMaxOption = struct('offset',-10,...
                                     'fZeroWindow',[12 15],...
                                     'slidingWindowSize',5);
end
myexp.loadMapFromFile = false;
myexp.mapsAfterLoading = {'response','responseMax'};
% myexp.mapsAfterLoading = {'response', 'responseMax', 'localCorrelation'};
myexp.alignToTemplate = false;
% Step03 Open neuRoi GUI
myexp.planeNum = 2; % the plane number to open a trial, can also be modified in the GUI later
myexp.transformationName = 'transf';
myexp.calculatedTransformationsList = {'transf'};
myexp.referenceTrialIdx = 2;
mycon = NrController(myexp);
% myexp load already computed trZansformation
%mycon.openTrialFromList(12)
% Temporary
% myexp.selectedFileIdx = [13, 14];
%% Temporary
myexp.stackModel.roiGroupName = 'default';
%% Temporary
trial = myexp.getCurrentTrial();
trialCtrl = mycon.trialCtrlArray(1);
maskFile = '/media/hubo/WD_BoHu/Ca_imaging/results_tmp/2021-07-31-DpOBEM-JH17/Dp/stardist_mask/plane02/mask_merged_20210731_JH17_Dp_s2_o4arg_001_alignSlightOff.tif'
trial.importRoisFromMask(maskFile);
%% Save experiment after bunwarpj
% filePath = self.model.getDefaultFile('experiment');
% myexp.saveExperiment(self,filePath)
% neuRoi GUI > File > Save experiment
%% Step04 (For StarDist) Merge maps and save as RGB
trial = myexp.getCurrentTrial();
rgbDir = myexp.getDefaultDir('df_rgb');
if ~exist(rgbDir, 'dir')
    mkdir(rgbDir);
end
rgbSubdir = myexp.appendPlaneDir(rgbDir, myexp.planeNum);
if ~exist(rgbSubdir, 'dir')
    mkdir(rgbSubdir)
end
mapTypeList = {'anatomy','response','localCorrelation'};
mapDataList = trial.getMapDataList(mapTypeList);
fileName = sprintf('merged_%s.tif',trial.fileBaseName);
filePath = fullfile(rgbSubdir,fileName);
imwrite(mapDataList,filePath);
%% Step05 (For StarDist) Print python command to run stardist prediction
% Currently, you need to copy paste this command to a terminal window under directory stardist_pred/, and run the python script. Hopefully this step will be optimized in the future
maskDir = myexp.getDefaultDir('stardist_mask');
if ~exist(maskDir,'dir')
    mkdir(maskDir)
end
maskSubdir = myexp.appendPlaneDir(maskDir, myexp.planeNum);
if ~exist(maskSubdir,'dir')
    mkdir(maskSubdir)
end

stardistCmd = sprintf('python predict_mergedRGB.py %s %s',...
                      rgbSubdir, maskSubdir)
% Account for path change in docker
stardistCmd = replace(stardistCmd, '/media/hubo/WD_BoHu/Ca_imaging', '/disk_ca_imaging');

disp(stardistCmd)
%% Step06 Import stardist mask into trial
% Use the File menu > Import ROIs from mask
% Then modify the ROIs if necessary
% Afterwards, click File menu > Save ROis, to save the ROIs in the neuRoi format
%% Step07 Get trial table
% This step is to sort the raw data files according to odor conditions
% remove the extrials that you do not want to include in further analysis
myexp.arrangeTrialTable();
disp(myexp.trialTable)
%% Step07-cont. Remove extra trials
removeIdx = [21,25,26,28]; % 07-31-Dp

if length(removeIdx)
    myexp.removeTrialFromTable(removeIdx);
    myexp.trialTable.trialNum = [];
    myexp.trialTable = batch.addTrialNum(myexp.trialTable);
end
disp(myexp.trialTable)

%% Step08 Select trials for futher processing, e.g. trial stack, extract time trace
myexp.selectedFileIdx = sort(myexp.trialTable.fileIdx);

%% Step09 Alignment across trials
% neuRoi GUI Calculate Bunwarpj button
% myexp.applyBunwarpj();
% neuRoi GUI Inspect trials


%% Step09 Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROIs in each trial
% If you accidentally closed the GUI, the following code might
% throw an error. In that case, just run Step01, then continue with
% Step03
myexp.alignToTemplate = true;
myexp.trialOptionRaw = struct('process',true,...
                              'noSignalWindow',[1 6]);
planeNum = 3;
templateIdx = 17; % the index of the file which corresponds to the ROI template. Currently all ROIs are drawn on one trial and applied to all other trials. This should be optimized in the future, when we have a combinged ROI template from many trials
planeString = NrModel.getPlaneString(planeNum);

prefix = '';
appendix = '_RoiArray';
ext = 'mat';

totalN = length(fileIdxList);
roiIdxList = repmat(templateIdx,totalN,1);
roiFileNameList = cellfun(@(x) iopath.modifyFileName(x,prefix,appendix,'mat'),myexp.rawFileList(roiIdxList),'UniformOutput',false);
roiFileList = cellfun(@(x) fullfile(myexp.roiDir,planeString,x), ...
                      roiFileNameList,'UniformOutput',false);
disp(roiFileList)

%% Step08 Extract
plotTrace = true;
myexp.alignToTemplate = true;
myexp.extractTimeTraceBatch(fileIdxList, ...
                            roiFileList,planeNum, ...
                            plotTrace);   
%% Step09 (Optional) Save a sorted time trace list for further
% processing by Python
% planeNum = 4;
planeString = NrModel.getPlaneString(planeNum);
traceResultDir = fullfile(myexp.resultDir,'time_trace', ...
                          planeString);
% Sort file names by odor
nTrialPerOdor = 3;
odorList = myexp.expInfo.odorList

fileNameArraySorted = myexp.trialTable.FileName;
odorArraySorted = myexp.trialTable.Cond;

% Load time trace matrices
traceResultArray = struct('timeTraceMat',{},'roiArray',{},...
                          'roiFilePath',{},'rawFilePath',{});
appendix = sprintf('_frame%dtoInfby4',planeNum);
for k=1:length(fileNameArraySorted)
    fileName = fileNameArraySorted{k};
    timeTraceFilePath = shortcut.getTimeTraceFilePath(traceResultDir,fileName,appendix);
    foo = load(timeTraceFilePath);
    traceResultArray(k) = foo.traceResult;
end

% Keep only the ROIs that appear in all trials
[commonRoiTagArray,timeTraceMatList,idxMat] = ...
    analysis.findCommonRoi(traceResultArray,'removePointRoi', true);

% Save time trace
timeTraceDataFilePath = fullfile(traceResultDir, ...
                                 'timetrace.mat');
save(timeTraceDataFilePath,'timeTraceMatList','odorArraySorted','odorList')
