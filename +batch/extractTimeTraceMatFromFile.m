function extractTimeTraceMatFromFile(rawDataDir,rawFileList, ...
                                     roiTemplateFilePath,traceDir, ...
                                     trialOption,offsetYxMat, ...
                                     sm,plotTrace)

if plotTrace
    timeTraceFig = figure();
    nrow = 4;
    ncol = ceil(length(rawFileList)/4);
end

for idx = 1:length(rawFileList)
    disp(sprintf('Extract time trace from %d th file',idx))
    rawFileName = rawFileList{idx};
    disp(rawFileName)
    rawFilePath = fullfile(rawDataDir,rawFileName);
    
    offsetYx = offsetYxMat(idx,:);
    trialOptionCell = helper.structToNameValPair(trialOption)
    trial = TrialModel(rawFilePath,'yxShift',offsetYx,trialOptionCell{:});
    trial.loadRoiArray(roiTemplateFilePath,'replace');
    [timeTraceMat,roiArray] = trial.extractTimeTraceMat(trial.intensityOffset,sm);
    if plotTrace
        figure(timeTraceFig)
        subplot(nrow,ncol,idx)
        imagesc(timeTraceMat)
    end

    dataFileBaseName = trial.name;
    if sm
        resFileName = sprintf('%s_traceResult_sm%d.mat',dataFileBaseName,sm);
    else
        resFileName = [dataFileBaseName '_traceResult.mat'];
    end
    resFilePath = fullfile(traceDir,resFileName);
    traceResult.timeTraceMat = timeTraceMat;
    traceResult.roiArray = roiArray;
    traceResult.roiFilePath = roiTemplateFilePath;
    traceResult.rawFilePath = rawFilePath;

    save(resFilePath,'traceResult')
end


