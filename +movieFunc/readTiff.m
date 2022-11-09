function imageData = readTiff(filePath)
% READTIFF read (single plane) TIFF file
if exist(filePath, 'file')
    tifLink = Tiff(filePath, 'r');
    imageData = tifLink.read();
else
    error(sprintf('File does not exist! %s',filePath))
end
