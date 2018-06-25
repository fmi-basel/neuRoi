% read movie movie
% implementation of the Tiff-read library by Anastasios Moressis (March 2016)
function rawMovie = readMovie(filePath,meta,varargin)
    if nargin == 2
        nFrame = meta.numberframes;
        startFrame = 1;
    elseif nargin == 4
        nFrame = varargin{1};
        startFrame = varargin{2};
    else
        error('Usage: readMovie(filePath,meta,[nFrame,startFrame])');
    end
    
    if startFrame > meta.numberframes
        error(sprintf(['Start frame %d exceeded total number of ' ...
                       'frames %d!'],startFrame,meta.numberframes));
    end
    
    if startFrame+nFrame > meta.numberframes
        error(sprintf(['Frame number (%d + %d) exceeded total number of ' ...
               'frames (%d)!'],startFrame,nFrame,meta.numberframes));
    end
    
    warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TifLink = Tiff(filePath, 'r');
    rawMovie = zeros(meta.height,meta.width,nFrame,'uint16');
    for i = 1:nFrame
        if mod(i,50) == 0; disp(strcat(num2str(i),12,'frames read')); end
        TifLink.setDirectory(startFrame+i-1);
        rawMovie(:,:,i) = TifLink.read();
    end
    TifLink.close();
end
