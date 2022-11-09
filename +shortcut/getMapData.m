function mapData = getMapData(filePath,loadMovieOption,preprocessOption,varargin)
trial = TrialModel(filePath,loadMovieOption,preprocessOption);
map = trial.calculateAndAddNewMap(varargin{:});
mapData = map.data;



