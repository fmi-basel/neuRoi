function expStruct = createTestExperiment()
trialStructList = {}
trialStructList{1} = createTestMovie()
trialStructList{2}= createTestMovie('ampList', [2, 2, 3]);
A = [2 0 0; 0.33 1 0; 0 0 1];

% transform one of the movies

testStruct.trial = TrialModel('mockMovie', mockMovie);

% Save trial movie
% Initiate experiment

expStruct.myexp = myexp;
expStruct.trialStructList = trialStructList

end
