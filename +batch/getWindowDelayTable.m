function joinedTable = getWindowDelayTable(fileTable,odorList,odorDelayList)

delayTable = table(odorList',odorDelayList','VariableNames', ...
                   {'Odor','Delay'});
delayTable.Odor = categorical(delayTable.Odor,categories(fileTable.Odor))

joinedTable = outerjoin(fileTable,delayTable,'Type','Left','MergeKeys',true);
