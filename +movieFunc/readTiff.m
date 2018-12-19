function imageData = readTiff(filePath)
% READTIFF read (single plane) TIFF file
tifLink = Tiff(filePath, 'r');
imageData = tifLink.read();
