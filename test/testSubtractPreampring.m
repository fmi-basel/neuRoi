%% Add path
addpath('..')
%% Clear
close all
clear all
%% File path
dataDir = '/media/hubo/Bo_FMI/Data/two_photon_imaging/';
subDir = '2018-09-04-EM';
fileNameArray={'BH18_41dpf_f1_z75_s1_o1ala_002_.tif',...
               'BH18_41dpf_f1_z75_s3_o3ala_001_.tif'};
filePathArray = cellfun(@(x) fullfile(dataDir,subDir,x), ...
                        fileNameArray,'UniformOutput',false);
filePath = filePathArray{1};
%% Load movie
movieMeta = movieFunc.readMeta(filePath);
rawMovie = movieFunc.readMovie(filePath,movieMeta);
%%
noSignalWindow = [1 12];
[subMovie,templ] = movieFunc.subtractPreampRing(rawMovie, ...
                                                noSignalWindow);
%% subtract template directly
noSignalAvg = mean(rawMovie(:,:,noSignalWindow(1): ...
                            noSignalWindow(2)),3);


%% Show template
imagesc(templ)

%% Show averaged movies
rawMovieAvg = mean(rawMovie,3);
subMovieAvg = mean(subMovie,3);
figure()
imagesc(rawMovieAvg)
figure()
imagesc(subMovieAvg)
%% Load anatomy images
resultDir = '/home/hubo/Projects/Ca_imaging/results/';
alignResultDir = fullfile(resultDir,subDir,'alignmentTest');
anatomyArrayFilePath = fullfile(alignResultDir,'anatomyArray.mat');
load(anatomyArrayFilePath)
ana = anatomyArray{1};
%% Subtract baseline
% intensityOffset = min(min(anatomyArray{1}));
% for k=1:2
%     anatomyArray{k} = anatomyArray{k} - intensityOffset;
% end

%% subtract template directly
noSignalWindow = [1 12];
noSignalAvg = mean(rawMovie(:,:,noSignalWindow(1): ...
                            noSignalWindow(2)),3);
noSignalAvgOdd = mean(noSignalAvg(1:2:end,:),1);
noSignalAvgEven = mean(noSignalAvg(2:2:end,:),1);
for k = 1:size(noSignalAvg,1)/2
    template(2*k-1,:) = noSignalAvgOdd;
    template(2*k,:) = noSignalAvgEven;
end

% anaNoSig = ana - noSignalAvg;

