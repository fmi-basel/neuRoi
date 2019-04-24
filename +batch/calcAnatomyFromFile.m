function anatomyArray = calcAnatomyFromFile(inDir,fileNameArray, ...
                                            outDir,varargin)
% CALCANATOMYFROMFILE Calculate anatomy map from files in a directory
% Args:
%     inDir (char): input directory.
%     fileNameArray (cell array): array containing input file names.
%     outDir (char): output directory.
%     addtional arguments: options for load trials.

% Returns:
%     anatomyArray (N*M*K matrix): array of anatomy images, N and M
%     are dimensions of the anatomy images, K is the dimension of
%     each file.
nFile = length(fileNameArray)

for k=1:nFile
    fileName = fileNameArray{k}
    filePath = fullfile(inDir,fileName);
    disp(sprintf('Loading %dth file:',k))
    disp(filePath)
    trial = TrialModel(filePath,varargin{:});
    map = trial.calculateAndAddNewMap('anatomy');
    if k == 1
        mapSize = size(map.data);
        anatomyArray = zeros(mapSize(1),mapSize(2),nFile);
    end
    anatomyArray(:,:,k) = map.data;
    if length(outDir)
        outFileName = iopath.getAnatomyFileName(fileName);
        outFilePath = fullfile(outDir,outFileName);
        movieFunc.saveTiff(movieFunc.convertToUint(map.data),outFilePath);
    end
end

