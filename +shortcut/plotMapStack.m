function fig = plotMapStack(mapArray,filePathArray,zlim,nCol,mapType)
nMap = length(mapArray);
nRow = ceil((nMap+1)/nCol);

figWidth = 1800;
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
    if strcmp(mapType,'anatomy')
        colormap(gray)
    end
end
subplot(nRow,nCol,nMap+1)
caxis(zlim)
if strcmp(mapType,'anatomy')
    colormap(gray)
end
colorbar('Location','west')
axis off

function depth = getDepth(filePath)
[~,fileBaseName,~] = fileparts(filePath);
depthStr = regexp(fileBaseName,'_(\d+)um_','tokens');
depthStr = depthStr{1}{1};
depth = str2num(depthStr);
