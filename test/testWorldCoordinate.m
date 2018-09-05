%% Clear var
clear all
%% Create 2-D Spatial Referencing Object Knowing Image Size and World Limits
% Read a 2-D grayscale image into the workspace.

A = imread('pout.tif');
%% 
% Create an |imref2d| object, specifying the size and world limits of the 
% image associated with the object.
xWorldLimits = [2 5];
yWorldLimits = [3 6];
RA = imref2d(size(A),xWorldLimits,yWorldLimits)
%% 
% Display the image, specifying the spatial referencing object. The axes 
% coordinates reflect the world coordinates.
fig1 = figure;
img1 = imshow(A);
rawRoi = imfreehand;
roi.position = rawRoi.getPosition();
[xdata1,ydata1,cdata1] = getimage(img1);
roi.imageSize = size(cdata1);
%% haha
fig2 = figure;
img2 = imshow(A,RA);
%% x
pos = roi.position;
% [3 5; 4 5; 4 3];
%%
ax1 = fig1.Children(end);
p1 = patch(ax1,pos(:,1),pos(:,2),'red')
%% x
ax2 = fig2.Children(end);
p2 = patch(ax2,pos(:,1),pos(:,2),'green')
%% x
[xdata2,ydata2,cdata2] = getimage(img2);
imageSize = size(cdata2);
refObj = imref2d(imageSize,xdata2,ydata2);
[xWorld, yWorld] = intrinsicToWorld(refObj,pos(:,1),pos(:,2));
pos2 = [xWorld,yWorld];
%% x
ax2 = fig2.Children(end);
p22 = patch(ax2,pos2(:,1),pos2(:,2),'green')

