function c = structToNameValPair(s)
if isstruct(s)
    fn = fieldnames(s);
    vals = struct2cell(s);
    c = [fn(:),vals(:)].';
    c = c(:);
else
    c = {};
end   
