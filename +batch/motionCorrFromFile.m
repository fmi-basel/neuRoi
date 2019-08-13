function motionCorrFromFile(inDir,inFileList,trialOption,outDir)
if ~exist(outDir,'dir')
    mkdir(outDir)
end
nFile = length(inFileList);
referFrameRange = [31 40];
for k=1:nFile
    disp(sprintf('Start motion correction file %d',k))
    fileName = inFileList{k};
    filePath = fullfile(inDir,fileName);
    trialOptionCell = helper.structToNameValPair(trialOption);
    trial = TrialModel(filePath,trialOptionCell{:});
    referFrame = mean(trial.rawMovie(:,:,referFrameRange(1): ...
                                     referFrameRange(2)),3);
    referFrame = squeeze(referFrame);
    [offsety,offsetx] = movieFunc.alignWithinTrial(trial.rawMovie, ...
                                                   referFrame);
    offsetYx = [offsety;offsetx];
    
    [~,fileBaseName,~] = fileparts(fileName);
    outFileName = sprintf('%s_%s.mat','mcOffsetYx',fileBaseName);
    outPath = fullfile(outDir,outFileName);
    save(outPath,'offsetYx')
end
