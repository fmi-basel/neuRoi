function anaFileName = getAnatomyFileName(fileName)
[~,fileBaseName,~] = fileparts(fileName);
anaFileName = ['anatomy_' fileBaseName '.tif'];

