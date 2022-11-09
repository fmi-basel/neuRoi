function runIntersect = multiIntersect(setArray)
%MULTIINTERSECT Multiple set intersection.
%   MULTINTERSECT(setArray) when setArray is a cell array of vectors returns the values 
%   common to all vectors. The result will be sorted.
%
%   MULTIINTERSECT repeatedly evaluates INTERSECT on successive pairs of sets, 
%   which may not be very efficient.  For a large number of sets, this should
%   probably be reimplemented using some kind of tree algorithm.
%
%   Addpated from mintersect.m by David Fass
%   See also INTERSECT

runIntersect = setArray{1};
for i = 2:length(setArray),
    
    runIntersect = intersect(runIntersect,setArray{i});
    
    if isempty(runIntersect),
        return
    end
    
end

end

