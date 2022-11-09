function trialTable = addTrialNum(trialTable)
[group, id] = findgroups(trialTable.Cond);
trialNum = splitapply(@(x) {(1:length(x))'},trialTable.Cond,group);
trialNum = cell2mat(trialNum);

trialTable = [trialTable(:,1), table(trialNum,'VariableNames',{'trialNum'}), trialTable(:,2:end)];
