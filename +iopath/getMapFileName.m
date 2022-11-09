function mapFileName = getMapFileName(fileName,mapType,mapFileType)
[~,fileBaseName,~] = fileparts(fileName);
mapFileName = sprintf('%s_%s.%s',mapType,fileBaseName,mapFileType);

