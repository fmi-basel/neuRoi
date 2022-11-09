function ttFilePath = getTimeTraceFilePath(traceResultDir,filePath,...
                                                    appendix)
if ~exist('appendix','var')
    appendix = '';
end
[~,fileBaseName,~] = fileparts(filePath);
if appendix
    resFileName = [fileBaseName appendix '_traceResult.mat'];
else
    resFileName = [fileBaseName '_traceResult.mat'];
end
ttFilePath = fullfile(traceResultDir,resFileName);

