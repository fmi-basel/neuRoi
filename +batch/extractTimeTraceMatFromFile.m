function extractTimeTraceMatFromFile(rawDataDir,rawFileList, ...
                                     roiTemplateFilePath,traceDir, ...
                                     trialOption,offsetYxMat, ...
                                     sm,plotTrace)
    % EXTRACTTIMETRACEMATFROMFILE extract time trace from files as
    % batch processing. Note that this is no longer used in NrModel
    if ~exist(roiTemplateFilePath,'file')
        error('ROI file does not exists!')
    end

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
    trialOptionCell = helper.structToNameValPair(trialOption);
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


