function mapStackPath = getMapStackPath(mapResultDir,odor,mapType,...
                                                  mapOption)
switch mapType
  case 'anatomy'
    optStr = '';
  case 'response'
    optStr = sprintf('%d-%d',mapOption.responseWindow(1), ...
                     mapOption.responseWindow(2));
  case 'responseMax'
    optStr = '';
end
mapFileName = sprintf('%s_%s_%s.svg',odor,mapType,optStr);

mapStackPath = fullfile(mapResultDir,mapFileName);
