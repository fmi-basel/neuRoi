function ttFilePath = getTimeTraceFilePath(filePath,traceResultDir)
[~,fileBaseName,~] = fileparts(filePath);
resFileName = [fileBaseName '_traceResult.mat'];
ttFilePath = fullfile(traceResultDir,resFileName);

