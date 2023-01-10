function stack = loadStack(inDir, fileNameArray)
    [~, ~, fileExt] = fileparts(fileNameArray{1});
    nFile = length(fileNameArray);

    disp(sprintf('Loading stack from %s', inDir))
    for k=1:nFile
        fileName = fileNameArray{k};
        filePath = fullfile(inDir, fileName);
        if k==1
            firstTif = loadFile(filePath, fileExt);
            stack = zeros([size(firstTif),nFile]);
            if strcmp(fileExt, '.tif')
                switch class(firstTif)
                  case 'uint8'
                    stack = uint8(stack);
                  case 'uint16'
                    stack = uint16(stack);
                end
            end
            stack(:,:,k) = firstTif;
        else
            stack(:,:,k) = loadFile(filePath, fileExt);
        end
    end
end

function data = loadFile(filePath, fileExt)
    if strcmp(fileExt, '.tif')
        data = movieFunc.readTiff(filePath);
    elseif strcmp(fileExt, '.mat')
        foo = load(filePath);
        data = foo.map.data;
    else
        error(sprintf('Cannot load file %s extension can only be .tif or .mat!', filePath))
    end
end
