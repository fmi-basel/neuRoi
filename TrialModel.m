classdef TrialModel < handle
    properties
        filePath
        fileBaseName
        meta
        noSignalWindow
        loadMovieOption
        rawMovie
        
        roiArray
        selectedRoiIndArray
    end
        
    properties (Access = private)
        mapArray
    end
    
    properties (SetObservable)
        currentMapInd
    end
    
    events
        mapArrayLengthChanged
        mapUpdated
        trialDeleted
    end
    
    methods
        function self = TrialModel(varargin)
            if nargin == 1
                filePath = varargin{1};
            elseif nargin == 2
                filePath = varargin{1};
                loadMovieOption = varargin{2};
            else
                error(['Wrong usage!']);
            end
            
            if ~exist(filePath,'file')
                warning(['The file path does not exist! returning ' ...
                         'an empty TrialModel object.'])
                self.filePath = filePath;
                return
            end
            
            self.filePath = filePath;
            [~,self.fileBaseName,~] = fileparts(filePath);
            
            % Read data from file
            self.meta = movieFunc.readMeta(self.filePath);
            if ~exist('loadMovieOption','var')
                loadMovieOption = ...
                    self.calcDefaultLoadMovieOption();
            end
            self.loadMovieOption = loadMovieOption;
            self.loadMovie(self.filePath,loadMovieOption);
            
            % Initialize map array
            self.mapArray = {};
            
            % Initialize ROI array
            self.roiArray = RoiFreehand.empty();
        end
        
        function loadMovie(self,filePath,loadMovieOption)
            if ~isnumeric(self.loadMovieOption.zrange)
                if strcmp(self.loadMovieOption.zrange,'all')
                    self.loadMovieOption.zrange = ...
                        [1,self.meta.totalNFrame];
                end
            end
            
            disp(loadMovieOption)
            disp('Loading movie ...')
            
            self.rawMovie = movieFunc.readMovie(filePath,...
                                      self.meta,...
                                      self.loadMovieOption.zrange,...
                                      self.loadMovieOption.nFramePerStep);
        end
        
        function nf = getNFrameRawMovie(self)
            nf = size(self.rawMovie,3);
        end
        
        function preprocessMovie(self,noSignalWindow)
            if ~exist('noSignalWindow','var')
                noSignalWindow = [1, 12];
            end
            self.rawMovie = movieFunc.subtractPreampRing(self.rawMovie,noSignalWindow);
        end
        
        function mapsize = getMapSize(self)
            mapsize = size(self.rawMovie(:,:,1));
        end
        
        function map = getMapByInd(self,ind)
            map = self.mapArray{ind};
        end
        
        function mapArrayLen = getMapArrayLength(self)
            mapArrayLen = length(self.mapArray);
        end
        
        function map = getCurrentMap(self)
            map = self.mapArray{self.currentMapInd};
        end
        
        function calculateAndAddNewMap(self,mapType,varargin)
            map.type = mapType;
            [map.data,map.option] = self.calculateMap(mapType,varargin{:});
            self.addMap(map);
        end
        
        function selectMap(self,ind)
            self.currentMapInd = ind;
        end
        
        function addMap(self,newMap)
            self.mapArray{end+1} = newMap;
            notify(self,'mapArrayLengthChanged');
        end
        
        function deleteMap(self,mapInd)
            self.mapArray(mapInd) = [];
            notify(self,'mapArrayLengthChanged');
        end
        
        function updateMap(self,mapInd,mapOption)
            map = self.mapArray{mapInd};
            [map.data,map.option] = self.calculateMap(map.type,mapOption);
            self.mapArray{mapInd} = map;
            notify(self,'mapUpdated',ArrayElementUpdateEvent(mapInd));
        end
        
        function saveContrastLimToCurrentMap(self,contrastLim)
            self.mapArray{self.currentMapInd}.contrastLim = ...
                contrastLim;
        end
        
        function [mapData,mapOption] = calculateMap(self,mapType,varargin)
            switch mapType
              case 'anatomy'
                [mapData,mapOption] = self.calcAnatomy(varargin{:});
              case 'response'
                [mapData,mapOption] = self.calcResponse(varargin{:});
              case 'responseMax'
                [mapData,mapOption] = self.calcResponseMax(varargin{:});
              case 'localCorrelation'
                [mapData,mapOption] = self.calcLocalCorrelation(varargin{:});
            end
        end

        function [mapData,mapOption] = calcAnatomy(self,varargin)
        % Method to calculate anatomy map
        % Usage: anatomyMap = nrmodel.calcAnatomy([nFrameLimit])
        % nFrameLimit: 1x2 array of two integers that specify the
        % beginning and end number of frames used to calculate the anatomy.
            if nargin == 1
                nFrameLimit = [1 size(self.rawMovie,3)];
            elseif nargin == 2
                if isfield(varargin{1},'nFrameLimit')
                    nFrameLimit = varargin{1}.nFrameLimit;
                else
                    nFrameLimit = varargin{1};
                end
            else
                error('Usage: nrmodel.calcAnatomy(''nFrameLimit'',nFrameLimit)')
            end
            
            if isempty(nFrameLimit)
                nFrameLimit = [1 size(self.rawMovie,3)];
            end

            if ~(length(nFrameLimit) && nFrameLimit(2)>= ...
                 nFrameLimit(1))
                error(['nFrameLimit should be an 1x2 integer array with ' ...
                       '2nd element bigger that the 1st one.']);
            end
            if nFrameLimit(1)<1 || nFrameLimit(2)>size(self.rawMovie,3)
                error(sprintf(['nFrameLimit [%d, %d] exceeded ' ...
                               'the frame number of the movie %d'],[nFrameLimit, size(self.rawMovie,3)]));
            end
            
            mapData = mean(self.rawMovie(:,:,nFrameLimit(1): ...
                                            nFrameLimit(2)),3);
            mapOption.nFrameLimit = nFrameLimit;
        end
        
        function [mapData,mapOption] = calcResponse(self,varargin)
        % Method to calculate response map (dF/F)
        % Usage: 
        % mymodel.calcResponse(offset,fZeroWindow,responseWindow) 
        % mymodel.calcResponse(mapOption)
        % mapOption is a structure that contains
        % offset,fZeroWindow,responseWindow in its field
            if nargin == 2
                mapOption = varargin{1};
            elseif nargin == 4
                mapOption = struct('offset',varargin{1}, ...
                                       'fZeroWindow',varargin{2}, ...
                                       'responseWindow', ...
                                       varargin{3});
            else
                error('Wrong usage!')
                help TrialModel.calcResponse
            end
            
            mapData = movieFunc.dFoverF(self.rawMovie,mapOption.offset, ...
                              mapOption.fZeroWindow, ...
                              mapOption.responseWindow);
        end
        
        function [mapData,mapOption] = calcResponseMax(self, ...
                                                       varargin)
            if nargin == 2
                mapOption = varargin{1};
            elseif nargin == 4
                mapOption = struct('offset',varargin{1}, ...
                                   'fZeroWindow',varargin{2}, ...
                                   'slidingWindowSize', ...
                                       varargin{3});
            else
                error('Wrong Usage!')
            end
            mapData = movieFunc.dFoverFMax(self.rawMovie,mapOption.offset,...
                                 mapOption.fZeroWindow,...
                                 mapOption.slidingWindowSize);
        end
        
        function [mapData,mapOption] = calcLocalCorrelation(self, ...
                                                            varargin)
            if nargin == 2
                if isstruct(varargin{1})
                    mapOption = varargin{1};
                else
                    mapOption.tileSize = varargin{1};
                end
            else
                error('Wrong Usage!');
            end
            mapData = movieFunc.computeLocalCorrelation(self.rawMovie,mapOption.tileSize);
        end
        
        % Methods for ROI-based processing
        function addRoi(self,varargin)
        % ADDROI add ROI to ROI array
        % input arguments can be a ROI structure
        % or position of a ROI, imageSize information
            
            if nargin == 3
                % isnumeric(varargin{1}) && ~isempty(varargin{2})
                % Add ROI from position
                position = varargin{1};
                imageInfo = varargin{2};
                invalidPosition = ~isempty(position) && ...
                    ~isequal(size(position,2),2);
                if invalidPosition
                    error('Invalid Position')
                end
                roi = RoiFreehand(0,position,imageInfo);
            elseif nargin == 2
                % Add ROI from structure
                if isstruct(varargin{1})
                    roiStruct = varargin{1}
                    roi = RoiFreehand(roiStruct)
                else
                    error(['Input should be a stucture!'])
                end
            else
                % TODO add ROI from mask
                error('Wrong usage!')
                help TrialModel.addRoi
            end

            roi.id = length(self.roiArray)+1;
            self.roiArray(end+1) = roi;
        end
        
        function selectRoi(self,ind)
            if isempty(self.selectedRoiIndArray) ||...
                    ~ismember(ind,self.selectedRoiIndArray)
                self.selectedRoiIndArray(end)  = ind;
            end
        end
        
        function updateRoi(self,ind,freshRoi)
            freshRoi.id = ind;
            self.roiArray(ind) = freshRoi;
        end
        
        function deleteRoi(self,ind)
            self.roiArray(ind) = [];
            if ind < length(self.roiArray)
                for k=ind:length(self.roiArray)
                    self.roiArray(k).id = k;
                end
            end
        end
        
    end
    
    methods
        function delete(self)
            notify(self,'trialDeleted');
        end
    end
    
    methods (Static)
        function option = calcDefaultLoadMovieOption(self)
            option.zrange = 'all';
            option.nFramePerStep = 1;
        end
    end
end
