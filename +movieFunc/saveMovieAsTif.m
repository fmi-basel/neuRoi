function saveMovieAsTif(filePath,movieMat)
tifHandle = Tiff(filePath,'w');

tagStruct.ImageLength = size(movieMat,1);
tagStruct.ImageWidth = size(movieMat,2);
tagStruct.Photometric = Tiff.Photometric.MinIsBlack;
tagStruct.BitsPerSample = 16;
tagStruct.SamplesPerPixel = 1;
tagStruct.RowsPerStrip = 16;
tagStruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagStruct.Software = 'MATLAB';

tagStruct1 = tagStruct;
tagStruct1.SubIFD = 2 ;  % required to create subdirectories
setTag(tifHandle,tagStruct1)
write(tifHandle,movieMat(:,:,1));
for k=2:size(movieMat,3)
    writeDirectory(tifHandle);
    setTag(tifHandle,tagStruct)
    write(tifHandle,movieMat(:,:,k));
end
