function sortedFileTable = sortFileNameByOdor(fileList,odorList,fileOdorList)
if ~exist('fileOdorList','var')
    fileOdorList = cellfun(@iopath.getOdorFromFileName,...
                           fileList,...
                           'UniformOutput',false);
end

fileTable = table(fileList',fileOdorList','VariableNames', ...
                  {'FileName','Odor'});
fileTable.Odor = categorical(fileTable.Odor,odorList);
sortedFileTable = sortrows(fileTable,'Odor');
end

