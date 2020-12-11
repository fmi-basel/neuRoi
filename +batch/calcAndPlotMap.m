function calcAndPlotMap(exp, inFileType, mapType, mapOption, trialOption,...
                        fileIdx, planeNum)
mapArray = exp.calcMapBatch(inFileType,...
                            mapType,mapOption,...
                            'trialOption',trialOption,...
                            'planeNum',planeNum,...
                            'fileIdx',fileIdx);

% Save MAT file
outDir = fullfile(exp.resultDir, sprintf('%s_map',mapType));
fileName = sprintf('%s_map_plane%d.mat',mapType,planeNum);
filePath = fullfile(outDir,fileName);

save(filePath,'mapArray','trialTable','fileIdx')
%% Plot dF/F maps
climit = [0 1];
sm = 3;
batch.plotMaps(responseArray,trialTable,climit,clut2b,sm)
%% Save dF/F map
responseDir = fullfile(myexp.resultDir, 'response_map');
if ~exist(responseDir, 'dir')
    mkdir(responseDir)
end
responseMapFileName = sprintf('responseMap_plane%d.pdf',planeNum);
responseMapFilePath = fullfile(responseDir,responseMapFileName);
                               
saveas(gcf,responseMapFilePath)

end

