function intersection = rangeIntersect(ra,rb)
% RANGEINTERSECT calculates the intersection between two ranges
% Usage: intersection = rangeIntersect(ra,rb)
% ra and rb are both 1x2 array, with first element smaller than the
% second element
if ra(1)>=ra(2) || rb(1)>=rb(2)
    error(['The 1st element should be smaller than 2nd element in ' ...
           'each array']);
end
    
rc(1) = max(ra(1),rb(1));
rc(2) = min(ra(2),rb(2));
if rc(1) < rc(2)
    intersection = rc;
else
    intersection = [];
end
