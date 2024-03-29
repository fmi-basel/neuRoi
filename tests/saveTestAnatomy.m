function fileList = saveTestAnatomy(tmpExpDir, movieStructList)
    nTrial = length(movieStructList);
    fileList = arrayfun(@(x) sprintf('anatomy%02d.tif', x), 1:nTrial,...
                        'UniformOutput', false);
    for k=1:nTrial
        movieFunc.saveTiff(uint8(movieStructList{k}.anatomy),...
                  fullfile(tmpExpDir, fileList{k}));
    end
end
