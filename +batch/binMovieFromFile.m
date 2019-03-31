function outFileNameArray = binMovieFromFile(inDir,fileNameArray,shrinkFactors,outDir,varargin)
% BINMOVIEFROMFILE bin movies from files in a directory
%     Args:
%         inDir (char): input directory
%         fileNameArray (cell array): array containing input file
%         names.
%         shrinkFactors (1x3 array): shrink factor on x, y and z
%         axis.
%         outDir (char): output directory.
%         addtional variables: options for loading movie, see TrialModel
%     Returns:
%         no return value

nFile = length(fileNameArray)

for k=1:nFile
    disp(sprintf('Binning %d th file',k))
    fileName = fileNameArray{k};
    disp(fileName)
    filePath = fullfile(inDir,fileName);
    trial = TrialModel(filePath,varargin{:});
    binned = movieFunc.binMovie(trial.rawMovie,shrinkFactors, ...
                                'mean');
    outFileName = iopath.getBinnedFileName(fileName,shrinkFactors);
    outFilePath = fullfile(outDir,outFileName);
    movieFunc.saveTiff(movieFunc.convertToUint(binned,8), ...
                       outFilePath)
end


