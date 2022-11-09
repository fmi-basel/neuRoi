function [runArray,idxMat] = multipleIntersect(arrayList)
runArray = arrayList{1};
idxMat = zeros(length(arrayList),length(runArray));
idxMat(1,:) = 1:length(runArray);
for k=2:length(arrayList)
    [runArray,idx1,idx2] = intersect(runArray,arrayList{k});
    idxMat = idxMat(:,idx1);
    idxMat(k,:) = idx2;
end

    
