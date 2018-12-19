function ttFilePath = getTimeTraceFilePath(traceResultDir,filePath,...
                                                    appendix)
if ~exist('appendix','var')
    appendix = '';
end
[~,fileBaseName,~] = fileparts(filePath);
if appendix
    resFileName = [fileBaseName '_traceResult_' appendix '.mat'];
else
    resFileName = [fileBaseName '_traceResult.mat'];
end
ttFilePath = fullfile(traceResultDir,resFileName);

