function [anatomyArray,filePrefix] = calcAnatomyFromFile(inDir,fileNameArray, ...
                                                      outDir,trialOption)
% CALCANATOMYFROMFILE Calculate anatomy map from files in a directory
% Args:
%     inDir (char): input directory.
%     fileNameArray (cell array): array containing input file names.
%     outDir (char): output directory.
%     trialOption: options for load trials.

% Returns:
%     anatomyArray (N*M*K matrix): array of anatomy images, N and M
%     are dimensions of the anatomy images, K is the dimension of
%     each file.
%     filePrefix: prefix attached to raw file names as output file
%     names.

if ~exist('trialOption','var')
    trialOption = {};
end

nFile = length(fileNameArray);
filePrefix = iopath.getAnatomyFilePrefix();
for k=1:nFile
    fileName = fileNameArray{k};
    filePath = fullfile(inDir,fileName);
    if ~isfile(filePath)
        msgId = 'batchCalcAnatomyFromFile:fileNotFound';
        msg = sprintf('File not found! %s',filePath);
        error(msgId,msg)
    end
    disp(sprintf('Loading %dth file:',k))
    disp(filePath)
    trial = TrialModel(filePath,trialOption{:});
    map = trial.calculateAndAddNewMap('anatomy');
    if k == 1
        mapSize = size(map.data);
        anatomyArray = zeros(mapSize(1),mapSize(2),nFile);
    end
    anatomyArray(:,:,k) = map.data;
    if length(outDir)
        outFileName = iopath.modifyFileName(fileName,filePrefix,'','tif');
        outFilePath = fullfile(outDir,outFileName);
        movieFunc.saveTiff(movieFunc.convertToUint(map.data),outFilePath);
    end
end

