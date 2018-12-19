function plotTimeTraceAvgRow(timeTraceAvgArray,timeTraceSemArray,frameRate, ...
                             odorList,yRange,lineColor)
    if ~exist('lineColor','var')
        lineColor = 'b';
    end
tvec = (1:size(timeTraceAvgArray{1},2))/frameRate;
nOdor = length(timeTraceAvgArray);
fig = figure('InnerPosition',[200 500 1900 210]);
axArray = gobjects(1,nOdor);
% axArray = helper.tight_subplot(1,nOdor)
for k=1:nOdor
    subplot(1,nOdor,k)
    %axes(axArray(k))
    axArray(k) = gca;
    %plot(tvec,timeTraceAvgArray{k})
    boundedline(tvec,timeTraceAvgArray{k},timeTraceSemArray{k},lineColor)
    % errorbar(tvec,timeTraceAvgArray{k},timeTraceSemArray{k})
    ylim(yRange)
    xlim([0 tvec(end)])
    xticks(0:10:tvec(end))
    if k>1
        set(gca,'yTick',[]);
    end
    odor = odorList(k);
    %ylabel(odor)
    set(gca, 'FontSize', 12)
end
linkaxes(axArray,'xy')
%xlabel('Time (s)')

