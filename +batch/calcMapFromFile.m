function mapArray = calcMapFromFile(inDir,fileNameList,mapType,varargin)

% Optional input arguments
% outDir
% trialOption
% outFileType

pa = inputParser;
addRequired(pa,'inDir',@ischar)
addRequired(pa,'fileNameList',@iscell)
addRequired(pa,'mapType')
addParameter(pa,'mapOption',[])
addParameter(pa,'windowDelayList',[])
addParameter(pa,'outDir',[])
addParameter(pa,'trialOption',{})
addParameter(pa,'outFileType','mat')

parse(pa,inDir,fileNameList,mapType,varargin{:})
pr = pa.Results;

nFile = length(pr.fileNameList)

for k=1:nFile
    fileName = pr.fileNameList{k}
    filePath = fullfile(pr.inDir,fileName);
    disp(sprintf('Loading %dth file:',k))
    disp(filePath)
    trial = TrialModel(filePath,pr.trialOption{:});
        
    if ~isempty(pr.mapOption)
        mapOption = pr.mapOption;
        if ~isempty(pr.windowDelayList) && strcmp(mapType, ...
                                                  'response')
            delay = pr.windowDelayList(k);
            mapOption.responseWindow = mapOption.responseWindow + ...
                delay;
        end
        % disp(mapOption)
        map = trial.calculateAndAddNewMap(pr.mapType,mapOption);
    else
        map = trial.calculateAndAddNewMap(pr.mapType);
    end
    
    if k == 1
        mapSize = size(map.data);
        mapArray = zeros(mapSize(1),mapSize(2),nFile);
    end
    mapArray(:,:,k) = map.data;
    if length(pr.outDir)
        outFileName = iopath.getMapFileName(fileName,pr.mapType,pr.outFileType);
        outFilePath = fullfile(pr.outDir,outFileName);
        if strcmp(pr.outFileType,'tif')
            movieFunc.saveTiff(movieFunc.convertToUint(map.data), ...
                               outFilePath);
        elseif strcmp(pr.outFileType,'mat')
            save(outFilePath)
        end
    end
end

mapMeta = pr;
metaFilePath = fullfile(pr.outDir,'mapMeta.json');
helper.saveStructAsJson(mapMeta,metaFilePath);
