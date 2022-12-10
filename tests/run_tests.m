addpath('..')
% testCase = TrialModelTest;
% results = testCase.run
% testCase = BUnwarpJ.BUnwarpJTest;
% results = testCase.run
% testCase = NrModelTest;
% results = testCase.run
% testCase = TrialStackModelTest;
% results = testCase.run
disp('xxxxxx')
disp('xxxxxx')
disp('xxxxxx')
% testCase = trialStack.TrialStackControllerTest;
testCase = NrControllerTest;
results = testCase.run
% close all
