function calcAndSaveMapStack(filePathArray,loadMovieOption,preprocessOption,...
                             mapResultDir,mapType, ...
                             varargin)
if strcmp(mapType,'response')
    if length(varargin) == 1
        mapOption = varargin{1};
    elseif length(varargin) == 2
        mapOption = varargin{1};
        frameOffsetArray = varargin{2};
    end 
end
for k=1:length(filePathArray)
    filePath = filePathArray{k};
    if strcmp(mapType,'response')
        if exist('frameOffsetArray','var')
            newMapOption = mapOption;
            newMapOption.responseWindow = newMapOption.responseWindow + ...
                frameOffsetArray(k);
        else
            newMapOption = mapOption;
        end
        disp(newMapOption)
        mapData = shortcut.getMapData(filePath,loadMovieOption,preprocessOption,...
                                      mapType,newMapOption);
        mapFilePath = shortcut.getMapFilePath(filePath, ...
                                              mapResultDir,mapType, ...
                                              newMapOption);
    else
        mapData = shortcut.getMapData(filePath,loadMovieOption,preprocessOption,...
                                      mapType,varargin{:});
        mapFilePath = shortcut.getMapFilePath(filePath, ...
                                              mapResultDir,mapType,varargin{:});
    end
    save(mapFilePath,'mapData')
end

