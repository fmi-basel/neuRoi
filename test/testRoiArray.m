%% Add path
addpath('..')
%% Clear variables
clear all

%% Initiate TrialModel obj
trial = TrialModel('xx');

%% Add Roi
roi = RoiFreehand([10 12], [2 3;4 5;3 1]);
for k=1:10
    trial.addRoi(roi);
end
%% Display Rois
arrayfun(@(x) disp(x.tag),trial.roiArray)
%% Display Roi pos
arrayfun(@(x) disp(x.position),trial.roiArray)

%% delete
trial.deleteRoi(3)
arrayfun(@(x) disp(x.tag),trial.roiArray)
%% add
trial.addRoi(roi);
arrayfun(@(x) disp(x.tag),trial.roiArray)
%% update
roi2 = RoiFreehand([10 12], [2 3;4 5]);
trial.updateRoi(4,roi2)
arrayfun(@(x) disp(x.position),trial.roiArray)
%% selectRoi
trial.selectRoi(0)
trial.selectedRoiTagArray

