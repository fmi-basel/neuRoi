function stFileNameArray = sortFileNameArray(fileNameArray,sortBy, ...
                                             order)
switch sortBy
  case 'odor'
    odorArray = cellfun(@shortcut.getOdorFromFileName,...
                        fileNameArray,...
                        'UniformOutput',false);
    rankArray = cellfun(@(x) sortNameToRank(x,order),odorArray);
    
    [rankSorted,rankOrder] = sort(rankArray);
    stFileNameArray = fileNameArray(rankOrder);
end

function rank = sortNameToRank(sortName,order)
rank = find(strcmp(sortName,order));
