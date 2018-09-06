function testFindRoiByTagArray()
tic
ra = linspace(1,1e5,1e5);
ta = randperm(1e4)+9e4-10;
% ra = [12 13 15 17 18 19];
% ta = [17 12 18 13];
% ta  = [17 14 12];

% tia = arrayfun(@(x) findFirstInd(x,ta),ra);
% mria = find(tia>0);
% mtia = tia(mria);
% [smtia,omtia] = sort(mtia);
% ria = mria(omtia);
   
ria = arrayfun(@(x) findFirstInd(x,ra),ta);
toc





function ind = findFirstInd(x,v)
ind = find(x==v,1);
if ~isempty(ind)
    ind = ind(1);
else
    ind = NaN;
end

