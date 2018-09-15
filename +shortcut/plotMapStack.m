function plotMapStack(mapArray,filePathArray,zlim,nCol)
nMap = length(mapArray);
nRow = ceil(nMap/nCol);

figWidth = 1700;
figHeight = 300*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
for k=1:nMap
    subplot(nRow,nCol,k)
    imagesc(mapArray{k})
    ax = gca;
    ax.Visible = 'off';
    depth = getDepth(filePathArray{k});
    titleStr = sprintf('%d um',depth);
    title(titleStr);
    set(get(ax,'Title'),'Visible','on');
    caxis(zlim)
end

function depth = getDepth(filePath)
[~,fileBaseName,~] = fileparts(filePath);
depthStr = regexp(fileBaseName,'_(\d+)um_','tokens');
depthStr = depthStr{1}{1};
depth = str2num(depthStr);
