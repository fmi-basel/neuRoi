function saveTestMovies(tmpExpDir, movieStructList)
    nTrial = length(movieStructList);
    rawFileList = arrayfun(@(x) sprintf('trial%02d.tif', x), 1:nTrial);
    % Save trial movie
    for k=1:nTrial
        saveMovie(trialStructList{k}.rawMovie,...
                  fullfile(tmpExpDir, rawFileList{k}));
    end
    
end

function saveMovie(rawMovie, filePath)
    movieFunc.saveTiff(uint8(rawMovie), filePath);
end
