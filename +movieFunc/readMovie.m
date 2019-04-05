function rawMovie = readMovie(filePath,meta,varargin)
% READMOVIE read movie from TIFF file into a 3D array
% Usage: readMovie(filePath,meta,[frameRange,[nFramePerStep]])
% filePath: the path to TIFF file.
% meta: a structure that contains .totalNFrame(total number of
% frames), .height and .width (height and width of image in number
% of pixels)
% frameRange: 1x2 array specifying the number of the starting and
% ending frame;
% nFramePerStep: the step size of loading the frame (load every
% nFramePerStep frame from data);
    
    if nargin == 2
        frameRange = [1,meta.totalNFrame];;
        nFramePerStep = 1;
    elseif nargin == 3
        frameRange = varargin{1};
        nFramePerStep = 1;
    elseif nargin == 4
        frameRange = varargin{1};
        nFramePerStep = varargin{2};
    else
        error('Wrong usage!');
        help movieFunc.readMovie
    end
    
    if frameRange(1) > frameRange(2)
        error(sprintf(['End frame %d should be equal or larger than the ' ...
                       'starting frame %d'],framgeRange(1), ...
                      framgeRange(2)));
    end
    
    if frameRange(2) > meta.totalNFrame
        error(sprintf(['End frame %d exceeded total number of ' ...
                       'frames %d!'],frameRange(2),meta.totalNFrame));
    end
    
    if nFramePerStep <= 0
        error('nFramePerStep should be a positive integer')
    end
    
    warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TifLink = Tiff(filePath, 'r');
    frameNumArray = frameRange(1):nFramePerStep:frameRange(2);
    nFrame = length(frameNumArray);
    uintType = sprintf('uint%d',meta.bitsPerSample);
    rawMovie = zeros(meta.height,meta.width,nFrame,uintType);

    for k = 1:nFrame
        if mod(k,50) == 0
            disp(sprintf('%d frames read',k))
        end
        fn = frameNumArray(k);
        TifLink.setDirectory(fn);
        rawMovie(:,:,k) = TifLink.read();
    end
    TifLink.close();
    warning('on','all');
end
