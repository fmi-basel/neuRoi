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
filePathArray = cellfun(@(x) fullfile(dataDir,subDir,x), ...
                        fileNameArray,'UniformOutput',false);
roiResultDir = fullfile(resultDir,subDir,'roiArray');
%% Alignment Directory
alignResultDir = fullfile(resultDir,subDir,'alignment');
%% Load offsetYxMat
filePath = fullfile(alignResultDir,'regResult.mat');
foo = load(filePath);
regResult = foo.regResult;
offsetYxMat = regResult.offsetYxMat;

%% Open neuRoi GUI
mymodel = NrModel(filePathArray);
mymodel.loadMovieOption = struct('zrange','all',...
                                 'nFramePerStep',1);
mymodel.offsetYxMat = offsetYxMat;
mymodel.preprocessOption = struct('process',true,...
                                  'noSignalWindow',[1 12]);
mymodel.intensityOffset = -10;
mymodel.resultDir = roiResultDir;

mycontroller = NrController(mymodel);

%% Get current trial
currentTrialInd = mymodel.currentTrialInd;
trial = mymodel.getTrialByInd(currentTrialInd);
% trcon = mycontroller.trialControllerArray(currentTrialInd);
%% responseMap
responseOption = struct('offset',mymodel.intensityOffset,...
                        'fZeroWindow',[100 200],...
                        'responseWindow',[400 600]);
trial.calculateAndAddNewMap('response',responseOption);
%trial.updateMap(2,responseOption)
%% responseMax map
responseMaxOption = struct('offset',mymodel.intensityOffset,...
                        'fZeroWindow',[100 200],...
                        'slidingWindowSize',100);
trial.calculateAndAddNewMap('responseMax',responseMaxOption);
%% localCorrelation map
localCorrelationOption.tileSize = 16;
trial.calculateAndAddNewMap('localCorrelation', ...
                            localCorrelationOption);

%% More response map
responseOption = struct('offset',mymodel.intensityOffset,...
                        'fZeroWindow',[100 200],...
                        'responseWindow',[300 450]);
%trial.calculateAndAddNewMap('response',responseOption);
trial.updateMap(5,responseOption)


%% TODO
% TODO time trace starting point

%% Delete ROIs with only one point
% Get current trial
currentTrialInd = mymodel.currentTrialInd;
trial = mymodel.getTrialByInd(currentTrialInd);
roiArray = trial.roiArray;
deleteTagArray = {};
for k = 1:length(roiArray)
    roi = roiArray(k);
    if size(roi.position,1)<2
        deleteTagArray{end+1} = roi.tag;
    end
end
%% Delete point ROIs
for k=1:length(deleteTagArray)
    tag = deleteTagArray{k};
    trial.deleteRoi(tag);
end
%% Time trace directory
traceResultDir = fullfile(resultDir,subDir,'timeTrace');
%% Extract time traces from current trial
currentTrialInd = mymodel.currentTrialInd;
trial = mymodel.getTrialByInd(currentTrialInd);
[timeTraceMat,roiTagArray] = trial.extractTimeTraceMat();

dataFileBaseName = trial.fileBaseName;
resFileName = [dataFileBaseName '_traceResult.mat'];
resFilePath = fullfile(traceResultDir,resFileName);
save(resFilePath,'timeTraceMat','roiTagArray')
%% Plot time traces
figure('Name',dataFileBaseName)
imagesc(timeTraceMat)
