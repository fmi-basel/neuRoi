%% Add path
addpath('..')
%% Clear variables
close all
clear all
% %% Generate image data
% A = 50*rand(5,6);
% %% Save generated image
% save('randImg.mat','A')
%% Load image
load('randImg.mat')
% Default XData and YData
fig1 = figure;
img1 = image(A);
ax1 = get(fig1,'CurrentAxes');

axis image
title('Image Displayed with Intrinsic Coordinates');

% Nondefault XData and YData
x = [19.5 23.5];
y = [8.0 12.0];
fig2 = figure;
image(A,'XData',x,'YData',y)
ax2 = get(fig2,'CurrentAxes');

axis image
title('Image Displayed with Nondefault Coordinates');
%% Roi on default image
roiRaw = imfreehand(ax1);
% Save to RoiFreehand object
imageSize = size(A);
position = roiRaw.getPosition();
roi = RoiFreehand(imageSize,position);

% %% Artifical ROI
% imageSize = size(A);
% position = [2 5;2 4;3 4];
% roi = RoiFreehand(imageSize,position);

% Plot ROI patch
pt = roi.createRoiPatch(ax1);
pt = roi.createRoiPatch(ax2);

%% Roi on image 2
roiRaw = imfreehand(ax2);
% Save to RoiFreehand object
% position = roiRaw.getPosition();
roi = RoiFreehand(ax2,roiRaw);

%% Plot ROI patch
pt = roi.createRoiPatch(ax1);
pt = roi.createRoiPatch(ax2);

%% Create mask from ROI
mask = roi.createMask();
figure
image(mask)
colormap(cool(2))
axis image
title('Mask from roi1')
