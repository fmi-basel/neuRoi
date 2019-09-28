function [stFileNameArray,varargout] = sortFileNameArray(fileNameArray,sortBy, ...
                                             order)
switch sortBy
  case 'odor'
    odorArray = cellfun(@shortcut.getOdorFromFileName,...
                        fileNameArray,...
                        'UniformOutput',false);
    rankArray = cellfun(@(x) sortNameToRank(x,order),odorArray);
    
    [rankSorted,rankOrder] = sort(rankArray);
    stFileNameArray = fileNameArray(rankOrder);
    if nargout
        varargout{1} = odorArray(rankOrder);
    end
end

function rank = sortNameToRank(sortName,order)
rank = find(strcmp(sortName,order));
