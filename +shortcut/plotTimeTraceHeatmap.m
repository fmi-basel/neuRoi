function plotTimeTraceHeatmap(timeTraceMatArray,filePathArray, ...
                              nOdor,nTrialPerOdor,zlim)
nCol = nOdor+1;
nRow = nTrialPerOdor;
nSubplot = length(timeTraceMatArray);
indMat = reshape(1:nRow*nCol,nCol,nRow).';

figWidth = 1800;
figHeight = 300*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
for k=1:nSubplot
    subplot(nRow,nCol,indMat(k))
    imagesc(timeTraceMatArray{k})
    % ax.Visible = 'off';
    if mod(k,nRow) == 1
        ax = gca;
        odor = shortcut.getOdorFromFileName(filePathArray{k});
        title(odor);
        set(get(ax,'Title'),'Visible','on');
    end
    caxis(zlim)
end
subplot(nRow,nCol,indMat(nSubplot+1))
caxis(zlim)
colorbar('Location','west')
axis off

