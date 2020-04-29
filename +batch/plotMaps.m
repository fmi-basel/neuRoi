function plotMaps(mapArray,trialTable,climit,clrmap,sm)
% assume mapArray and trialTable are sorted according to cond
% condList = categories(trialTable.Cond);
if ~exist('climit','var')
    climit = [];
end
    
if ~exist('clrmap','var')
    clrmap = 'default';
end

if ~exist('sm','var')
    sm = 0;
end

mapArrayType = class(mapArray);

condList = categories(trialTable.Cond);
if climit
    nCol = length(condList)+1;
else
    nCol = length(condList);
end

nRow = max(trialTable.trialNum);
if strcmp(mapArrayType,'cell')
    nMap = length(mapArray);
else
    nMap = size(mapArray,3);
end

figWidth = 1800;
figHeight = 300*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
ha = helper.tight_subplot(nRow,nCol,[.01 .01],[.1 .04],[.01 .01]);
touched = zeros(1,length(ha));
for k=1:nMap
    condIdx = double(trialTable.Cond(k));
    trialNum = trialTable.trialNum(k);
    subplotIdx = nCol*(trialNum-1)+condIdx;
    % subplot(nRow,nCol,subplotIdx)
    axes(ha(subplotIdx));
    touched(subplotIdx) = 1;
    if strcmp(mapArrayType,'cell')
        mapData = mapArray{k};
    else
        mapData = mapArray(:,:,k);
    end
    
    if sm
        mapData = conv2(mapData,fspecial('gaussian',[3 3], sm),'same');
    end
    
    imagesc(mapData)
    colormap(clrmap)
    if climit
        caxis(climit)
    end
    
    ax = gca;
    ax.Visible = 'off';
end

for k=1:(nCol-1)
    % subplot(nRow,nCol,k)
    axes(ha(k));
    cond = cellstr(condList(k));
    cond = cond{:};
    title(cond);
    ax = gca;
    set(get(ax,'Title'),'Visible','on');
end

if climit
    % subplot(nRow,nCol,nCol)
    axes(ha(nCol));
    touched(nCol) = 1;
    caxis(climit)
    colorbar('Location','west')
    axis off
end

for k=1:length(ha)
    if touched(k) == 0
        delete(ha(k))
    end
end
