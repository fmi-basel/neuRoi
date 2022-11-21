addpath('..')
% testCase = TrialModelTest;
% results = testCase.run
% testCase = BUnwarpJ.BUnwarpJTest;
% results = testCase.run
% testCase = NrModelTest;
% results = testCase.run
% testCase = TrialStackModelTest;
% results = testCase.run
testCase = trialStack.TrialStackControllerTest;
results = testCase.run
% close all
