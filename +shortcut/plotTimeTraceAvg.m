function plotTimeTraceAvg(timeTraceAvgArray,frameRate,odorList)
tvec = (1:size(timeTraceAvgArray{1},2))/frameRate;
nOdor = length(timeTraceAvgArray);
fig = figure;
axArray = gobjects(1,nOdor);
yLimit = [0 15];
for k=1:nOdor
    subplot(nOdor,1,k)
    axArray(k) = gca;
    plot(tvec,timeTraceAvgArray{k})
    %boundedline(tvec,timeTraceAvgArray{k},timeTraceSemArray{k})
    % errorbar(tvec,timeTraceAvgArray{k},timeTraceSemArray{k})
    ylim(yLimit)
    if k<nOdor
        set(gca,'XTick',[]);
    end
    odor = odorList(k);
    ylabel(odor)
end
linkaxes(axArray,'xy')
xlabel('Time (s)')
