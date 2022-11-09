function stack = loadStack(inDir,fileNameArray, type)
nFile = length(fileNameArray);

for k=1:nFile
    fileName = fileNameArray{k};
    filePath = fullfile(inDir, fileName);
    if k==1
        firstTif = movieFunc.readTiff(filePath);
        stack = zeros([size(firstTif),nFile]);
        switch class(firstTif)
          case 'uint8'
            stack = uint8(stack);
          case 'uint16'
            stack = uint16(stack);
        end
        stack(:,:,k) = firstTif;
    else
        stack(:,:,k) = movieFunc.readTiff(filePath);
    end
end
