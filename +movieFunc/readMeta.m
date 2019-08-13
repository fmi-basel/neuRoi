function meta = readMeta(filePath)
% READMETA read meta data of a TIFF file
imgInfoArr = imfinfo(filePath);
imgInfo = imgInfoArr(1);
meta.width = imgInfo.Width;
meta.height = imgInfo.Height;
meta.totalNFrame = numel(imgInfoArr);
meta.bitsPerSample = imgInfo.BitsPerSample;

