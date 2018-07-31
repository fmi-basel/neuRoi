%% Add path
addpath('..')
%% Clear variables
clear all
%% Test GUI
handles = neuRoiGui();
mapButtonGroup = handles.mapButtonGroup;
mapButtonArray = mapButtonGroup.Children;
set(mapButtonGroup,'SelectionChangedFcn',...
                  @(src,evnt)disp(sprintf('seleted %s',evnt.NewValue.Tag)));
% set(mapButtonArray(5),'Callback',@(src,evnt)disp(sprintf('seleted %s',src.Tag)));


%% Test Callback

set(mapButtonGroup,'SelectedObject',mapButtonArray(5))
% mapButtonArray(5).Value = 1;
% for k=1:6;disp(mapButtonArray(k).Value);end
