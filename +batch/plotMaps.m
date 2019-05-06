function plotMaps(mapArray,trialTable,nTrialPerOdor,climit)
% assume mapArray and trialTable are sorted according to odor
% odorList = categories(trialTable.Odor);
odorList = unique(trialTable.Odor);

nCol = length(odorList)+1;
nRow = nTrialPerOdor;
nSubplot = size(mapArray,3);
indMat = reshape(1:nRow*nCol,nCol,nRow).';

figWidth = 1800;
figHeight = 300*nRow;
fig = figure('InnerPosition',[200 500 figWidth figHeight]);
for k=1:nSubplot
    subplot(nRow,nCol,indMat(k))
    imagesc(mapArray(:,:,k))
    ax = gca;
    ax.Visible = 'off';
    if mod(k,nRow) == 1
        odor = cellstr(trialTable.Odor(k));
        odor = odor{:};
        title(odor);
        set(get(ax,'Title'),'Visible','on');
    end
    caxis(climit)
end
subplot(nRow,nCol,indMat(nSubplot+1))
caxis(climit)
colorbar('Location','west')
axis off


