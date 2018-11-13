function plotTimeTraceHeatmap(timeTraceMatArray,filePathArray, ...
                              nOdor,nTrialPerOdor,frameRate,zlim)
nCol = nOdor+1;
nRow = nTrialPerOdor;
nSubplot = length(timeTraceMatArray);
indMat = reshape(1:nRow*nCol,nCol,nRow).';

tvec = [0 5 10 15 20 25 30];
ttvec = tvec * frameRate;
tstringvec = arrayfun(@(x) num2str(x),tvec,'Uniformoutput',false);

figWidth = 1800;
figHeight = 220*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
gap = 0.02;
axArray  = helper.tight_subplot(nRow,nCol,gap);
for k=1:nSubplot
    % subplot(nRow,nCol,indMat(k))
    % axArray(k) = gca;
    axes(axArray(indMat(k)))
    imagesc(timeTraceMatArray{k})
    % heatmap(timeTraceMatArray{k}, 'Colormap', flipud(pink))
    % ax.Visible = 'off';
    if mod(k,nRow) == 1
        ax = gca;
        odor = shortcut.getOdorFromFileName(filePathArray{k});
        title(odor);
        set(get(ax,'Title'),'Visible','on');
    end
    colormap(flipud(pink))
    caxis(zlim)
    
    if k>nRow
        set(gca,'YTick',[]);
    end
    
    if mod(k,nRow)
        set(gca,'XTick',[]);
    else
        xticks(ttvec)
        xticklabels(tstringvec)
    end

end
linkaxes(axArray(1:end-nRow),'xy')

axes(axArray(indMat(nSubplot+1)))
caxis(zlim)
colorbar('Location','west')
axis off

for k=1:nRow-1
    delete(axArray(indMat(end-k+1)))
end

% [ax1,h1]=helper.suplabel('Time (s)');
% [ax2,h2]=helper.suplabel('#neuron','y');

