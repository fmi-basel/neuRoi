%% add path
addpath('../')
%% clear vars
close all
clear all
%% test align

imgA = imread('cameraman.tif');
imgB = imtranslate(imgA,[0 4]);

imgA = imgA(30:229,30:229);
imgB = imgB(30:229,30:229);

%% test on anatomy images
resultDir = '/home/hubo/Projects/Ca_imaging/results/';
subDir = '2018-09-04-EM';
alignResultDir = fullfile(resultDir,subDir,'alignmentTest');
anatomyArrayFilePath = fullfile(alignResultDir, ...
                                'anatomyArray.mat');
foo = load(anatomyArrayFilePath);
anaArr = foo.anatomyArray;
%% Filter images/Scale image
sigma = 2;
for k=1:2
    sm = imgaussfilt(anaArr{k},sigma);
    sm = anaArr{k};
    mx = max(sm(:));
    mn = min(sm(:));
    anaArrPr{k} = uint8((sm-mn)/(mx-mn)*255);
end

%% Assign
imgA = anaArrPr{1};
imgB = anaArrPr{2};
%% show original
figure
imshow(imgA)
figure
imshowpair(imgA,imgB,'Scaling','joint')

%% imregister
[optimizer, metric] = imregconfig('multimodal');
optimizer.InitialRadius = 0.009;
optimizer.Epsilon = 1.5e-4;
optimizer.GrowthFactor = 1.01;
optimizer.MaximumIterations = 300;
movingReg = imregister(imgB,imgA,'translation',optimizer, metric);
%% show
figure
imshowpair(imgA, movingReg,'Scaling','joint')
%% Align image manually
movieFunc.shiftImageManually(imgA,imgB)

%% alignImage from Peter
plotFig = false;
offset = movieFunc.alignImagePR(imgA,imgB,plotFig)
% imgC = imtranslate(imgB,-offset);
figure
imshowpair(imgA,imgB,'Scaling','joint')

if plotFig
    % fig1 = figure;
    % imshow(imgA)
    % figure(fig1)
    % title('A')


    % fig2 = figure;
    % imshow(imgB)
    % figure(fig2)
    % title('B')

    % figure
    % imshow(imgC)
    % title('C')
end

%% Test random images
imgA = rand(512);
offset = movieFunc.alignImagePR(imgA,imgA,true)
