function mapData = getMapData(filePath,loadMovieOption,varargin)
trial = TrialModel(filePath,loadMovieOption);
map = trial.calculateAndAddNewMap(varargin{:});
mapData = map.data;



