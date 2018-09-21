function mapStack = loadMapStack(filePathArray,mapResultDir,mapType, ...
                             varargin)
    if strcmp(mapType,'response')
        if length(varargin) == 1
            mapOption = varargin{1};
        elseif length(varargin) == 2
            mapOption = varargin{1};
            frameOffsetArray = varargin{2};
        end 
    end

    mapStack = {};
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
            mapFilePath = shortcut.getMapFilePath(filePath, ...
                                                  mapResultDir, ...
                                                  mapType,newMapOption);
        else
            mapFilePath = shortcut.getMapFilePath(filePath, ...
                                                  mapResultDir, ...
                                                  mapType,varargin{:});
        end

        foo = load(mapFilePath);
        try
            mapStack{k} = foo.mapData;
        catch
            mapStack{k} = foo.responseMap;
        end
    end
