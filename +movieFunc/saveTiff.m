function saveTiff(movieMat,filePath)
className = class(movieMat);
switch className
  case 'uint8'
    depth = 8;
  case 'uint16'
    depth = 16;
  otherwise
    error('movieMat should be uint8 or uint16!')
end

tifHandle = Tiff(filePath,'w');

tagStruct.ImageLength = size(movieMat,1);
tagStruct.ImageWidth = size(movieMat,2);
tagStruct.Photometric = Tiff.Photometric.MinIsBlack;
tagStruct.BitsPerSample = depth;
tagStruct.SamplesPerPixel = 1;
tagStruct.RowsPerStrip = 16;
tagStruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagStruct.Software = 'MATLAB';

if ndims(movieMat) == 2
    setTag(tifHandle,tagStruct);
    write(tifHandle,movieMat);
elseif ndims(movieMat) == 3
    tagStruct1 = tagStruct;
    tagStruct1.SubIFD = 2 ;  % required to create subdirectories
    setTag(tifHandle,tagStruct1)

    write(tifHandle,movieMat(:,:,1));
    for k=2:size(movieMat,3)
        writeDirectory(tifHandle);
        setTag(tifHandle,tagStruct)
        write(tifHandle,movieMat(:,:,k));
    end
else
    error('movieMat should be x*y or x*y*z matrix')
end
