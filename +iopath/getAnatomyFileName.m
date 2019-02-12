function anaFileName = getAnatomyFileName(fileName, trialOpt)
[~,fileBaseName,~] = fileparts(fileName);
trialName = TrialModel.getDefaultTrialName(fileBaseName, ...
                                           trialOpt.zrange,trialOpt.nFramePerStep);
anaFileName = ['anatomy_' trialName '.tif'];

