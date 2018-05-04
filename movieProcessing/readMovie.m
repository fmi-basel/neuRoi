% read movie movie
% implementation of the Tiff-read library by Anastasios Moressis (March 2016)
function rawMovie = readMovie(filePath,meta,nFrame, ...
                            startFrame,nPlane,planeNum)
    if nargin == 2
        nFrame = meta.numberframes;
        startFrame = 1;
        nPlane = 1;
        planeNum = 1;
    elseif nargin == 4
        nPlane = 1;
        planeNum = 1;
    elseif nargin == 6
        % TODO better argument parsing
    else
        error('Usage: readMovie(filePath,meta,[nFrame,startFrame,[nPlane,planeNum]])')
    end
    
    if mod(meta.numberframes,nPlane)
        warning(['Total number of frames does not divided number of ' ...
                 'planes!'])
    end
    
    if planeNum > nPlane
        error(['Error: plane number (%d) exceeded total number of ' ...
               'planes (%d)!'],planeNum,nPlane)
    end
    
    % Start from the specified plan
    if mod((startFrame - planeNum),nPlane)
        startFrame = floor(startFrame/nPlane) * nPlane + planeNum;
    end

    if startFrame > meta.numberframes
        error('Start frame exceeded total frames!')
    end
    
    if startFrame+(nFrame-1)*nPlane > meta.numberframes;
        nFrame = floor((meta.numberframes-startFrame)/nPlane);
        warning(['Number of frames exceeded. %d frames will be ' ...
                 'read.'],nFrame)
    end
    
    warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TifLink = Tiff(filePath, 'r');
    rawMovie = zeros(meta.height,meta.width,nFrame,'uint16');
    for i = 1:nFrame
        if mod(i,50) == 0; disp(strcat(num2str(i),12,'frames read')); end
        TifLink.setDirectory(startFrame+(i-1)*nPlane);
        rawMovie(:,:,i) = TifLink.read();
    end
    TifLink.close();
end
