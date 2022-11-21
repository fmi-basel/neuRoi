function rawFileList = saveTestMovies(tmpExpDir, movieStructList)
    nTrial = length(movieStructList);
    rawFileList = arrayfun(@(x) sprintf('trial%02d.tif', x), 1:nTrial,...
                           'UniformOutput', false);
    % Save trial movie
    for k=1:nTrial
        saveMovie(movieStructList{k}.rawMovie,...
                  fullfile(tmpExpDir, rawFileList{k}));
    end
    
end

function saveMovie(rawMovie, filePath)
    movieFunc.saveTiff(uint8(rawMovie), filePath);
end
