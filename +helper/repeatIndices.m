function ridxList = repeatIndices(idxList,totalN)
fullList = 1:totalN;
xx = sum(fullList>=idxList,1);
ridxList = idxList(xx);
