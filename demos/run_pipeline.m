%% Add path
addpath('../')
%% Create experiment database
clear expInfo
expInfo.odorList = {'ala','trp','ser','acsf','spont'};
expInfo.nTrial = 3;
expInfo.name = '2018-12-21-OBTel';
expInfo.rawFileList = {'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s1_o1trp_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s1_o2ala_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s1_o2ala_reference_002_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s1_o3ser_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s1_o4acsf_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s2_o1ala_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s2_o2trp_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s2_o3ser_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s2_o4acsf_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s3_o1ser_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s3_o2trp_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s3_o3ala_001_.tif',...
'20181221_BH18_29dpf_fish3_postTel_zm_z156um_moreVentral2_s3_o4acsf_001_.tif'};

expInfo.rawFileList = expInfo.rawFileList(1);
%% Define file path
dataRootDir = '/media/hubo/Bo_FMI/Ca_imaging/';
resultRootDir = '/home/hubo/Projects/Ca_imaging/results';

rawDataDir = fullfile(dataRootDir,'raw_data',expInfo.name);
procDataDir = fullfile(dataRootDir,'processed_data',expInfo.name);



%% Binning raw moive
% TODO deal with file not exist in TrialModel
% TODO number of frames after binning wrong
if ~exist(procDataDir)
    mkdir(procDataDir)
end
shrinkZ = 5;
shrinkFactors = [1, 1, shrinkZ];
noSignalWindow = [0 12];
% batch.binMovieFromFile(rawDataDir,expInfo.rawFileList, ...
%                        shrinkFactors,procDataDir,...
%                        'process',true,'noSignalWindow',noSignalWindow);
filePath = fullfile(rawDataDir,expInfo.rawFileList{1});
trial = TrialModel(filePath);
binned = movieFunc.binMovie(trial.rawMovie,shrinkFactors, ...
                                'mean');
%% Save Tiff
binnedCut = binned(:,:,1:5);
size(binnedCut)
outFilePath = '~/Desktop/test.tif';
movieFunc.saveTiff(movieFunc.convertToUint(binnedCut,8), ...
                   outFilePath);

%% Calculate anatomy maps (average over frames)
%% Align trials
%% Draw ROIs on representative trials
% todo automate combine ROI map?
%% Extract time trace with template ROI in all trials
% Apply template ROI map and correct ROI in each trial
%% Average time trace for each odor
%% Thresholding and determine response window
%% Calculate response maps
