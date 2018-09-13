classdef TrialModel < handle
    properties
        filePath
        fileBaseName
        resultDir
        
        meta
        preprocessOption
        loadMovieOption
        rawMovie
        
        yxShift
        
        roiFilePath
        roiArray
        
        intensityOffset
    end
        
    properties (Access = private)
        mapArray
    end
    
    properties (SetObservable)
        currentMapInd
        roiVisible
        selectedRoiTagArray
        syncTimeTrace
    end
    
    properties (Constant)
        MAX_N_ROI = 200
    end
    
    events
        mapArrayLengthChanged
        mapUpdated
        
        roiAdded
        roiDeleted
        roiUpdated
        roiArrayReplaced
        
        roiSelected
        roiUnSelected
        roiSelectionCleared
        
        trialDeleted
    end
    
    methods
        function self = TrialModel(varargin)
            if nargin == 1
                filePath = varargin{1};
            elseif nargin == 2
                filePath = varargin{1};
                loadMovieOption = varargin{2};
            elseif nargin == 3
                filePath = varargin{1};
                loadMovieOption = varargin{2};
                preprocessOption = varargin{3}
            else
                error(['Wrong usage!']);
            end
            
            self.filePath = filePath;
            if ~exist(filePath,'file')
                warning(['The file path does not exist! returning ' ...
                         'an TrialModel object with a random ' ...
                         'movie.'])
                [~,self.fileBaseName,~] = fileparts(filePath);
                self.meta = struct('width',12,...
                                   'height',10,...
                                   'totalNFrame',5);
                self.rawMovie = rand(self.meta.height,...
                                     self.meta.width,...
                                     self.meta.totalNFrame);
            else
                [~,self.fileBaseName,~] = fileparts(filePath);
                
                % Read data from file
                self.meta = movieFunc.readMeta(self.filePath);
                if ~exist('loadMovieOption','var')
                    loadMovieOption = ...
                        TrialModel.calcDefaultLoadMovieOption();
                end
                self.loadMovieOption = loadMovieOption;
                self.loadMovie(self.filePath,loadMovieOption);
                
                % Preprocess movie
                if ~exist('preprocessOption','var')
                    self.preprocessOption = struct('process',true,...
                                              'noSignalWindow',[1 ...
                                        12]);
                else
                    self.preprocessOption = preprocessOption;
                end
                
                if self.preprocessOption.process
                    self.preprocessMovie(self.preprocessOption.noSignalWindow);
                end
            end
            
            % Offset from original movie
            self.yxShift = [0 0];
            
            % Directory for saving results
            self.resultDir = pwd;
            
            % Initialize map array
            self.mapArray = {};

            % Calculate anatomy map
            self.calculateAndAddNewMap('anatomy');
            
            % Initialize ROI array
            self.roiVisible = true;
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
        
        function shiftMovieYx(self,yxShift)
            disp('Shift movie by yxShift')
            disp(yxShift)
            self.yxShift = self.yxShift+yxShift;
            self.rawMovie = circshift(self.rawMovie,[yxShift 0]);
            nMap = self.getMapArrayLength();
            for k=1:nMap
                map = self.getMapByInd(nMap);
                map.data = circshift(map.data,yxShift);
                self.mapArray{k} = map;
                notify(self,'mapUpdated', ...
                   NrEvent.ArrayElementUpdateEvent(k));
            end

        end

        function transfromMovie2D(self,tform)
        end
        
        
        function mapSize = getMapSize(self)
            mapSize = size(self.rawMovie(:,:,1));
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
        
        function map = calculateAndAddNewMap(self,mapType,varargin)
            map.type = mapType;
            [map.data,map.option] = self.calculateMap(mapType,varargin{:});
            self.addMap(map);
        end
        
        function selectMap(self,ind)
            self.currentMapInd = ind;
        end
        
        function addMap(self,newMap)
            self.mapArray{end+1} = newMap;
            mapArrayLen = self.getMapArrayLength();
            self.selectMap(mapArrayLen);
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
            notify(self,'mapUpdated',NrEvent.ArrayElementUpdateEvent(mapInd));
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
        % TODO set roiArray to private
        function addRoi(self,varargin)
        % ADDROI add ROI to ROI array
        % input arguments can be a RoiFreehand object
        % or a structure containing position and imageSize
            
            if nargin == 2
                if isa(varargin{1},'RoiFreehand')
                    roi = varargin{1};
                elseif isstruct(varargin{1})
                    % Add ROI from structure
                    roiStruct = varargin{1};
                    roi = RoiFreehand(roiStruct);
                else
                    % TODO add ROI from mask
                    error('Wrong usage!')
                    help TrialModel.addRoi
                end
            else
                error('Wrong usage!')
                help TrialModel.addRoi
            end
            
            nRoi = length(self.roiArray);
            if nRoi >= self.MAX_N_ROI
                error('Maximum number of ROIs exceeded!')
            end
            
            self.checkRoiImageSize(roi);

            if isempty(self.roiArray)
                roi.tag = 1;
            else
                roi.tag = self.roiArray(end).tag+1;
            end
            self.roiArray(end+1) = roi;
            
            notify(self,'roiAdded')
        end
        
        function selectSingleRoi(self,varargin)
            if nargin == 2
                if strcmp(varargin{1},'last')
                    ind = length(self.roiArray);
                    tag = self.roiArray(ind).tag;
                else
                    tag = varargin{1};
                    ind = self.findRoiByTag(tag);
                end
            else
                error('Too Many/few input args!')
            end
            
            if ~isequal(self.selectedRoiTagArray,[tag])
                self.unselectAllRoi();
                self.selectRoi(tag);
            end
        end
        
        function selectRoi(self,tag)
            if ~ismember(tag,self.selectedRoiTagArray)
                ind = self.findRoiByTag(tag);
                self.selectedRoiTagArray(end+1)  = tag;
                notify(self,'roiSelected',NrEvent.RoiEvent(tag));
                disp(sprintf('ROI #%d selected',tag))
            end
        end
        
        function unselectRoi(self,tag)
            tagArray = self.selectedRoiTagArray;
            tagInd = find(tagArray == tag);
            if tagInd
                self.selectedRoiTagArray(tagInd) = [];
                notify(self,'roiUnSelected',NrEvent.RoiEvent(tag));
            end
        end
        
        function selectAllRoi(self)
        % TODO
        end
        
        function unselectAllRoi(self)
            self.selectedRoiTagArray = [];
            notify(self,'roiSelectionCleared');
        end
        
        function updateRoi(self,tag,varargin)
            ind = self.findRoiByTag(tag);
            oldRoi = self.roiArray(ind);
            freshRoi = RoiFreehand(varargin{:});
            freshRoi.tag = tag;
            self.checkRoiImageSize(freshRoi);
            self.roiArray(ind) = freshRoi;

            notify(self,'roiUpdated', ...
                   NrEvent.RoiUpdatedEvent(self.roiArray(ind)));
            disp(sprintf('Roi #%d updated',tag))
        end
        
        function deleteSelectedRoi(self)
            tagArray = self.selectedRoiTagArray;
            self.unselectAllRoi();
            indArray = self.findRoiByTagArray(tagArray);
            self.roiArray(indArray) = [];
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(tagArray));
        end
        
        function deleteRoi(self,tag)
            ind = self.findRoiByTag(tag);
            self.unselectRoi(tag);
            self.roiArray(ind) = [];
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent([tag]));
        end
        
        function roiArray = getRoiArray(self)
            roiArray = self.roiArray;
        end
        
        function roi = getRoiByTag(self,tag)
            if strcmp(tag,'end')
                roi = self.roiArray(end);
            else
                ind = self.findRoiByTag(tag);
                roi = self.roiArray(ind);
            end
        end
        
        function saveRoiArray(self,filePath)
            roiArray = self.roiArray;
            save(filePath,'roiArray');
        end
        
        function loadRoiArray(self,filePath,option)
            foo = load(filePath);
            roiArray = foo.roiArray;
            nRoi = length(roiArray);
                if nRoi >= self.MAX_N_ROI
                    error('Maximum number of ROIs exceeded!')
                end
            if strcmp(option,'merge')
                arrayfun(@(x) self.addRoi(x),roiArray);
            elseif strcmp(option,'replace')
                self.roiArray = roiArray;
                notify(self,'roiArrayReplaced');
            end
        end
        
        function checkRoiImageSize(self,roi)
            mapSize = self.getMapSize();
            if ~isequal(roi.imageSize,mapSize)
                error(['Image size of ROI does not match the map size ' ...
                       '(pixel size in x and y)!'])
            end
        end
        
        function ind = findRoiByTag(self,tag)
            ind = find(arrayfun(@(x) isequal(x.tag,tag), ...
                                self.roiArray),1);
            if ~isempty(ind)
                ind = ind(1);
            else
                error(sprintf('Cannot find ROI with tag %d!',tag))
            end
        end
        
        function roiIndArray = findRoiByTagArray(self,tagArray)
            roiIndArray = arrayfun(@(x) self.findRoiByTag(x), ...
                                   tagArray);
        end
        
        % Methods for time trace
        function timeTrace = getTimeTraceByTag(self,tag)
            ind = self.findRoiByTag(tag);
            roi = self.roiArray(ind);
            timeTrace = TrialModel.getTimeTrace(self.rawMovie,roi,...
                                                self.intensityOffset);
        end
        
        function [timeTraceMat,roiTagArray] = ...
                extractTimeTraceMat(self,varargin)
            if nargin == 1
                % intensityOffset does not change
            elseif nargin ==2
                self.intensityOffset = varargin{2};
            end
            nRoi = length(self.roiArray);
            timeTraceMat = zeros(nRoi,size(self.rawMovie,3));
            roiTagArray = zeros(1,nRoi);
            for k=1:nRoi
                roi = self.roiArray(k);
                timeTrace = TrialModel.getTimeTrace(self.rawMovie,roi,...
                                       self.intensityOffset);
                timeTraceMat(k,:) = timeTrace;
                roiTagArray(k) = roi.tag;
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
        
        function timeTraceDf = getTimeTrace(rawMovie,roi,varargin)
        % GETTIMETRACE get time trace of dF/F within a ROI
        % from the input raw movie
        % Usage: getTimeTrace(rawMovie,roi,[intensityOffset])
            
            if nargin == 2
                intensityOffset = 0;
            elseif nargin == 3
                intensityOffset = varargin{1};
            else
                error('Usage: getTimeTrace(rawMovie,roi,[intensityOffset])')
            end
            
            mask = roi.createMask;
            [maskIndX maskIndY] = find(mask==1);
            roiMovie = rawMovie(maskIndX,maskIndY,:);
            timeTraceRaw = mean(mean(roiMovie,1),2);
            timeTraceRaw =timeTraceRaw(:);

            timeTraceFg = timeTraceRaw - intensityOffset;
            timeTraceSm = smooth(timeTraceFg,10);
            fZero = quantile(timeTraceSm(10:end-10),0.1);
            
            % Time trace of dF/F, unit in percent
            timeTraceDf = (timeTraceSm - fZero) / fZero * 100;
        end
    end
end
