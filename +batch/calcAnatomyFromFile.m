function anatomyArray = calcAnatomyFromFile(inDir, fileNameArray, trialOpt, ...
                                    outDir)
% CALCANATOMY Calculate anatomy map from files in a directory
% Args:
%     inDir (string): input directory
%     fileNameArray (cell array): array containing input file names
%     trialOption (structure): options for load trials
%     outDir (string): output directory
% Returns:
%     anatomyArray (N*M*K matrix): array of anatomy images, N and M
%     are dimensions of the anatomy images, K is the dimension of
%     each file
nFile = length(fileNameArray)
filePathArray = cellfun(@(x) fullfile(inDir,x), ...
                        fileNameArray,'UniformOutput',false);
anatomyArray = zeros(512,512,nFile);

for k=1:nFile
    filePath = filePathArray{k}
    disp(sprintf('Loading %dth file:',k))
    disp(filePath)
    trial = TrialModel(filePath,trialOpt.zrange, ...
                      trialOpt.nFramePerStep,trialOpt.process,trialOpt.noSignalWindow);
    map = trial.calculateAndAddNewMap('anatomy');
    anatomyArray(:,:,k) = map.data;
    if length(outDir)
        outFileName = ['anatomy_' trial.name '.tif'];
        outFilePath = fullfile(outDir,outFileName);
        movieFunc.saveTiff(movieFunc.convertToUint(map.data),outFilePath);
    end
end

