addpath('..')
% testCase = TrialModelTest;
% results = testCase.run
% testCase = BUnwarpJ.BUnwarpJTest;
% results = testCase.run
% testCase = NrModelTest;
% results = testCase.run
disp('xxxxxx')
disp('xxxxxx')
disp('xxxxxx')
% testCase = trialStack.TrialStackModelTest;
% results = testCase.run
% testCase = trialStack.TrialStackControllerTest;
% results = testCase.run
% testCase = NrControllerTest;
% results = testCase.run
% close all
% testCase = trialMvc.TrialModelTest;
% results = testCase.run
% testCase = trialMvc.TrialModelTest;
testCase = nrOpticFlow.OpticFlowTest;
results = testCase.run

% results = runtests('trialMvc.TrialControllerTest','Name','testSelectRoisByOverlay');

