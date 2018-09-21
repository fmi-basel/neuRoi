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
               
% Alignment Directory
alignResultDir = fullfile(resultDir,subDir,'alignment');
%% Get anatomy images
loadMovieOption = struct('zrange','all',...
                         'nFramePerStep',1);
preprocessOption = struct('preprocessOnLoading',true,...
                          'noSignalWindow',[1 12]);
for k=1:length(filePathArray)
    k
    filePath = filePathArray{k}
    anatomy = shortcut.getMapData(filePath,loadMovieOption, ...
                                           preprocessOption, ...
                                           'anatomy');
    anatomyArray{k} = anatomy;
end
%% Save anatomy images
anatomyArrayFileName = 'anatomyArray.mat';

anatomyArrayFilePath = fullfile(alignResultDir,anatomyArrayFileName);
save(anatomyArrayFilePath,'anatomyArray')
%% Display anatomy
nFile = length(filePathArray)
nCol = 5;
nRow = ceil(nFile/nCol);
figure
for k=1:nFile
    subplot(nRow,nCol,k);
    imagesc(anatomyArray{k})
    ax = gca;
    ax.Visible = 'off';
    colormap(gray)
end
%% Registrate images to template
templateInd = 9;
templateAna = anatomyArray{templateInd};
offsetYxMat = zeros(length(filePathArray),2);
plotfig = true;
% if plotfig
%     figure
%     nFile = length(filePathArray)
%     nCol = 5;
%     nRow = ceil(nFile/nCol);
% end
for k=1:length(filePathArray)
    offsetYx = movieFunc.alignImage(anatomyArray{k},templateAna);
                          
    offsetYxMat(k,:) = offsetYx
    if plotfig
        % subplot(nRow,nCol,k);
        fig = figure
        fig.Name = [num2str(k) ': ' filePathArray{k}]
        newAna = movieFunc.shiftImage(anatomyArray{k},offsetYx);
        imshowpair(newAna,templateAna,'Scaling','joint');
    end
end
%% Save registration result
fileName = 'offsetYxMat.mat';
filePath = fullfile(alignResultDir,fileName);
save(filePath,'offsetYxMat')

regResult.filePathArray = filePathArray;
regResult.templateInd = templateInd;
regResult.offsetYxMat = offsetYxMat;
regResult.anatomyArray = anatomyArray;

fileName = 'regResult.mat';
filePath = fullfile(alignResultDir,fileName);
save(filePath,'regResult')
