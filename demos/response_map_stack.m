%% Add path
addpath('../../neuRoi');
%% Close figure
close all
%% Clear variabless
clear all
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
odorList =        {'ala','trp','ser','food','acsf','spont'};
frameOffsetList = [119    98     0   129    63   0];

fileNameArray = shortcut.sortFileNameArray(fileNameArray,'odor',odorList);
filePathArray = cellfun(@(x) fullfile(dataDir,subDir,x), ...
                        fileNameArray,'UniformOutput',false);
% Response map directory
responseResultDir = fullfile(resultDir,subDir,'responseMap');
if ~exist(responseResultDir,'dir')
    mkdir(responseResultDir)
end
%% Load movie option
loadMovieOption = struct('zrange','all',...
                                 'nFramePerStep',1);
preprocessOption = struct('process',true,...
                                  'noSignalWindow',[1 12]);
intensityOffset = -10;
%% Open neuRoi Gui for choosing the right response map option
mymodel = NrModel(filePathArray);
mymodel.loadMovieOption = loadMovieOption;
mymodel.preprocessOption = preprocessOption;
mymodel.intensityOffset = intensityOffset;
mycontroller = NrController(mymodel);
%% Get current trial
currentTrialInd = mymodel.currentTrialInd;
trial = mymodel.getTrialByInd(currentTrialInd);
% trcon = mycontroller.trialControllerArray(currentTrialInd);
%% responseMap
responseOptionInit1 = struct('offset',intensityOffset,...
                        'fZeroWindow',[100 200],...
                        'responseWindow',[330 450]);
% odor = shortcut.getOdorFromFileName(trial.fileBaseName);
% odorInd = find(strcmp(odorList,odor));

% frameOffset = frameOffsetList(odorInd);
% responseOption1 = responseOptionInit1;
% responseOption1.responseWindow = responseOption1.responseWindow + frameOffset
% try
%     trial.updateMap(2,responseOption1)
% catch
%     trial.calculateAndAddNewMap('response',responseOption1);
% end

%% responseMax map
responseMaxOption = struct('offset',mymodel.intensityOffset,...
                        'fZeroWindow',[100 200],...
                        'slidingWindowSize',100);
trial.calculateAndAddNewMap('responseMax',responseMaxOption);

%% Second responseMap
responseOption2 = struct('offset',intensityOffset,...
                        'fZeroWindow',[100 200],...
                        'responseWindow',[750 950]);
try
    trial.updateMap(3,responseOption2)
catch
    trial.calculateAndAddNewMap('response',responseOption2);
end
%% Frame offset array
frameOffsetArray = zeros(1,length(fileNameArray));
for k=1:length(fileNameArray)
    fileName = fileNameArray(k);
    odor = shortcut.getOdorFromFileName(fileName);
    odorInd = find(strcmp(odorList,odor));
    frameOffsetArray(k) = frameOffsetList(odorInd);
end
frameOffsetArray

%% Save response maps
responseOption = responseOptionInit1;
shortcut.calcAndSaveMapStack(filePathArray,loadMovieOption,preprocessOption,...
                             responseResultDir,'response',responseOption,frameOffsetArray);
%% Load response maps
mapType = 'response';
responseOption = responseOptionInit1;
% responseMapStack = shortcut.loadMapStack(filePathArray, ...
%                                          responseResultDir,mapType,responseOption,frameOffsetArray);
responseMapStack = shortcut.loadMapStack(filePathArray,responseResultDir,mapType,responseOption);

%% Plot heat map
zlim = [0 0.3];
nCol = length(odorList)+1;
nRow = nTrialPerOdor;
nSubplot = length(responseMapStack);
indMat = reshape(1:nRow*nCol,nCol,nRow).';

figWidth = 500*nCol;
figHeight = 300*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
for k=1:nSubplot
    subplot(nRow,nCol,indMat(k))
    imagesc(responseMapStack{k})
    % ax.Visible = 'off';
    ax = gca;
    axis off
    if mod(k,nRow) == 1
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

%% Save response map plot
odor = 'all';
mapType = 'response';
mapStackPath = shortcut.getMapStackPath(responseResultDir,odor,mapType,responseOptionInit1)
saveas(fig,mapStackPath)




