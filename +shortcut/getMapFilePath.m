function mapFilePath = getMapFilePath(filePath,mapResultDir,mapType,varargin)
    [~,fileBaseName,~] = fileparts(filePath);
    switch mapType
      case 'anatomy'
        optStr = '';
      case 'response'
        responseOption = varargin{1};
        optStr = sprintf('%d_%d',responseOption.responseWindow(1), ...
                                 responseOption.responseWindow(2));
      case 'responseMax'
        optStr = '';
    end
    mapFileName = sprintf('%s_%s_%s.mat',fileBaseName,mapType,optStr);
    mapFilePath = fullfile(mapResultDir,mapFileName);
