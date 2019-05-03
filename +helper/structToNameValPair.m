function c = structToNameValPair(s)
fn = fieldnames(s);
vals = struct2cell(s);
c = [fn(:),vals(:)].';
c = c(:);
