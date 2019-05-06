function trialTable = getTrialTable(fileList,odorList,fileOdorList)
if ~exist('fileOdorList','var')
    fileOdorList = cellfun(@iopath.getOdorFromFileName,...
                           fileList,...
                           'UniformOutput',false);
end

trialTable = table(fileList,fileOdorList,'VariableNames', ...
                  {'FileName','Odor'});
trialTable.Odor = categorical(trialTable.Odor,odorList);
end

