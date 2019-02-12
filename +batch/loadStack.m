function stack = loadStack(inDir,fileNameArray, type)
nFile = length(fileNameArray);
stack = zeros(512,512,nFile);
for k=1:nFile
    fileName = fileNameArray{k};
    filePath = fullfile(inDir, fileName);
    stack(:,:,k) = movieFunc.readTiff(filePath);
end
