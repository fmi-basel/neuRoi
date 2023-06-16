function binConfig = binMovieFromFile(inDir,inFileList,outDir,shrinkFactors,depth,method,trialOption)
% BINMOVIEFROMFILE bin movies from files in a directory
%     Args:
%         inDir (char): input directory
%         inFileList (cell array): array containing input file
%         names.
%         shrinkFactors (1x3 array): shrink factor on x, y and z
%         axis.
%         outDir (char): output directory.
%         addtional variables: options for loading movie, see TrialModel
%     Returns:
%         binConfig: configuration (including output directory,
%         parameters...) used to generate binned Movie
% Note that if the raw data type is not the same as the wanted data
% type, the data will first be normalized and converted to the
% wanted data type

if ~exist('depth','var')
    depth = 8;
end

if (depth ~= 8) && (depth ~=16)
    error('Depth should be 8 or 16 for uint8 or uint16!')
end

nFile = length(inFileList)

outFilePrefix = iopath.getBinnedFilePrefix(shrinkFactors);
for k=1:nFile
    disp(sprintf('Binning %d th file',k))
    fileName = inFileList{k};
    disp(fileName)
    filePath = fullfile(inDir,fileName);
    trialOptionCell = helper.structToNameValPair(trialOption);
    trial = TrialModel('filePath', filePath,trialOptionCell{:});
    binned = movieFunc.binMovie(trial.rawMovie,shrinkFactors, ...
                                method);
    
    outFileName = iopath.modifyFileName(fileName,outFilePrefix,'','tif');
    outFilePath = fullfile(outDir,outFileName);
    dataType = class(binned);
    wantedType = sprintf('uint%d',depth);
    if strcmp(dataType,wantedType)
        binned = rawMovie;
    else
        binned = movieFunc.convertToUint(binned,depth);
    end
    movieFunc.saveTiff(binned,outFilePath)
end
binConfig.inDir = inDir;
binConfig.inFileList = inFileList;
binConfig.outDir = outDir;
binConfig.filePrefix = outFilePrefix;
param.shrinkFactors = shrinkFactors;
param.depth = depth;
param.trialOption = trialOption;
binConfig.param = param;
