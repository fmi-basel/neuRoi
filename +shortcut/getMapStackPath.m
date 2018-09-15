function mapStackPath = getMapStackPath(responseResultDir,odor, ...
                                                  windowType)
mapStackPath = fullfile(responseResultDir,sprintf('response_%s_%s.pdf',odor,windowType]);

