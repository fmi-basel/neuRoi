function trialTable = getTrialTable(fileList,condList,fileCondList)
if ~exist('fileCondList','var')
    fileCondList = cellfun(@iopath.getOdorFromFileName,...
                           fileList,...
                           'UniformOutput',false);
end

trialTable = table(fileCondList,(1:length(fileList))',fileList,...
                   'VariableNames', {'Cond','fileIdx','FileName'});
trialTable.Cond = categorical(trialTable.Cond,condList);
trialTable = sortrows(trialTable,'Cond');

end
