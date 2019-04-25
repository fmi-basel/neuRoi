function binConfig = binMovieFromFile(inDir,inFileList,outDir,shrinkFactors,depth,trialOption)
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

if ~exist('depth','var')
    depth = 8;
end

nFile = length(inFileList)

outFilePrefix = iopath.getBinnedFilePrefix(shrinkFactors);
for k=1:nFile
    disp(sprintf('Binning %d th file',k))
    fileName = inFileList{k};
    disp(fileName)
    filePath = fullfile(inDir,fileName);
    trial = TrialModel(filePath,trialOption{:});
    binned = movieFunc.binMovie(trial.rawMovie,shrinkFactors, ...
                                'mean');
    
    outFileName = iopath.modifyFileName(fileName,outFilePrefix,'','tif');
    outFilePath = fullfile(outDir,outFileName);
    movieFunc.saveTiff(movieFunc.convertToUint(binned,depth), ...
                       outFilePath)
end
binConfig.inDir = inDir;
binConfig.inFileList = inFileList;
binConfig.outDir = outDir;
binConfig.filePrefix = outFilePrefix;
param.shrinkFactors = shrinkFactors;
param.depth = depth;
param.trialOption = trialOption;
binConfig.param = param;

timeStamp = helper.getTimeStamp
configFileName = ['binMeta-' timeStamp '.json'];
configFilePath = fullfile(outDir,configFileName);
helper.saveStructAsJson(binConfig,configFilePath);

