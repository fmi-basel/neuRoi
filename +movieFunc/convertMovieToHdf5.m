function convertMovieToHdf5(inFilePath,outFilePath)
meta = movieFunc.readMeta(inFilePath);
rawMovie = movieFunc.readMovie(inFilePath,meta);
h5create(outFilePath,'/rawMovie',size(rawMovie));
h5write(outFilePath,'/rawMovie',rawMovie);
