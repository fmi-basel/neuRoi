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
    trialOptionCell = helper.structToNameValPair(trialOption);
    trial = TrialModel(filePath,trialOptionCell{:});
    binned = movieFunc.binMovie(trial.rawMovie,shrinkFactors, ...
                                'mean');
    
    outFileName = iopath.modifyFileName(fileName,outFilePrefix,'','tif');
    outFilePath = fullfile(outDir,outFileName);
    if strcmp(class(binned),'double')
        binned = movieFunc.convertToUint(binned,depth);
    elseif strcmp(class(binned),'uint8') | strcmp(class(binned),'uint16')
        if depth == 8
            binned = uint8(binned);
        elseif depth == 16
            binned = uint16(binned);
        else
            error('Depth should be 8 or 16 for uint8 or uint16!')
        end
    else
        error(['Type error! Binned movie should be double or uint8 ' ...
               'or uint16!'])
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
