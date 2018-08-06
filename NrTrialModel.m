classdef NrTrialModel < handle
% NRTRIALMODEL the class in neuRoi that stores data of a single trial
% and does computation
% Properties:
% mapArray: the array that contains the 2-D maps that the user
% refer to for ROI drawing.
    
    properties (SetObservable)
        filePath
        fileBaseName
        meta
        noSignalWindow
        loadMovieOption
        
        rawMovie

        yxShift
        
        defaultResponseOption
        
        mapArray
        
        roiArray
        selectedRoiArray
        selectedTraceArray
        % roiMap
        % timeTraceArray
    end

    % properties (Access = private)
    %     mapArray
    % end
    
    methods
        function self = NrTrialModel(varargin)
            if nargin == 0
                filePath = '';
            elseif nargin == 1
                filePath = varargin{1};
            else
                error(['Wrong usage!']);
                help NrTrial
            end
            
            self.filePath = filePath;
            [~,self.fileBaseName,~] = fileparts(filePath);
                        
            self.yxShift = [0 0];
            
            % Initialize map array
            self.mapArray = {};
            
            % Initialize ROI array
            self.roiArray = {};
            
        end
        
        function readDataFromFile(self,loadMovieOption)
            self.meta = movieFunc.readMeta(self.filePath);
            if ~exist('loadMovieOption','var')
                loadMovieOption.startFrame = 1;
                loadMovieOption.nFrame = self.meta.numberframes;
            end
            self.loadMovie(self.filePath,loadMovieOption);
            self.loadMovieOption = loadMovieOption;
        end
        
        function loadMovie(self,filePath,loadMovieOption)
            startFrame = loadMovieOption.startFrame;
            nFrame = loadMovieOption.nFrame;
            self.rawMovie = movieFunc.readMovie(filePath,self.meta,nFrame,startFrame);
        end
        
        function preprocessMovie(self,noSignalWindow)
            if ~exist('noSignalWindow','var')
                noSignalWindow = [1, 12];
            end
            self.rawMovie = movieFunc.subtractPreampRing(self.rawMovie,noSignalWindow);
        end
        
        function shiftMovieYx(self,yxShift)
            self.yxShift = self.yxShift+yxShift;
            self.rawMovie = circshift(self.rawMovie,[yxShift 0]);
            self.anatomyMap = circshift(self.anatomyMap,yxShift);
            self.responseMap = circshift(self.responseMap,yxShift);
        end
        
        function unshiftMovieYx(self)
            self.shiftMovieYx(-self.yxShift);
        end
        
        function defaultResponseOption = ...
                calcDefaultResponseOption(self)
            nFrame = size(self.rawMovie,3);
            offset = -20;
            fZeroWindow = [ceil(nFrame*0.1),ceil(nFrame*0.2)];
            responseWindow = [ceil(nFrame*0.3),ceil(nFrame*0.4)];
            defaultResponseOption = struct('offset',offset, ...
                                           'fZeroWindow',fZeroWindow, ...
                                           'responseWindow',responseWindow);
        end
        
        function mapsize = getMapSize(self)
            mapsize = size(self.rawMovie(:,:,1));
        end
        
        function calculateAndAddNewMap(self,mapType,varargin)
            map.type = mapType;
            [map.data,map.option] = self.calculateMap(map.type,varargin{:});
            self.addMap(map);
        end
       
        function addMap(self,newMap)
            self.mapArray{end+1} = newMap;
        end
        
        function deleteMap(self,mapInd)
            self.mapArray(mapInd) = [];
        end
        
        function updateMap(self,mapInd,mapOption)
            map = self.mapArray{mapInd};
            [map.data,map.option] = self.calculateMap(map.type,mapOption);
            self.mapArray{mapInd} = map;
        end
        
        function map = getMapByInd(self,ind)
            map = self.mapArray{ind};
        end
        
        function mapArrayLen = getMapArrayLength(self)
            mapArrayLen = length(self.mapArray);
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
        % mymodel.calcResponse() calculate dF/F with default
        % parameters
        % mymodel.calcResponse(offset,fZeroWindow,responseWindow) 
        % mymodel.calcResponse(mapOption)
        % mapOption is a structure that contains
        % offset,fZeroWindow,responseWindow in its field
            if nargin == 1
                mapOption = self.defaultResponseOption;
            elseif nargin == 2
                mapOption = varargin{1};
            elseif nargin == 4
                mapOption = struct('offset',varargin{1}, ...
                                       'fZeroWindow',varargin{2}, ...
                                       'responseWindow', ...
                                       varargin{3});
            else
                error(['Usage: nrmodel.calcResponse(responseOpiton) ' ...
                       'or nrmodel.calcResponse(offset,fZeroWindow,responseWindow)'])
            end
            
            mapData = dFoverF(self.rawMovie,mapOption.offset, ...
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
            mapData = dFoverFMax(self.rawMovie,mapOption.offset,...
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
            mapData = computeLocalCorrelation(self.rawMovie,mapOption.tileSize);
        end
    end
    
    % Methods for ROI-based processing
    methods
        function addRoi(self,varargin)
        % ADDROI add ROI to ROI array
        % input argument can be a ROI structure
        % or position of a ROI, imageSize information
            
            if nargin == 3
                isnumeric(varargin{1}) && ~isempty(varargin{2})
                % Add ROI from position
                position = varargin{1};
                imageInfo = varargin{2};
                invalidPosition = ~isempty(position) && ~ ...
                    isequal(size(position,2),2);
                if invalidPosition
                    error('Invalid Position')
                end
                roi = RoiFreehand(0,position,imageInfo);
            elseif nargin == 2
                if isa(varargin{1},'RoiFreehand')
                % Add RoiFreehand object
                    
                    % TODO check id conflict
                    roi = varargin{1};
                elseif isstruct(varargin{1})
                    roiStruct = varargin{1}
                    roi = RoiFreehand(roiStruct)
                else
                    error(['Input should be a RoiFreehand or a ' ...
                           'stucture!'])
                end
            else
                % TODO add ROI from mask
                error('Wrong usage!')
                help NrTrial.addRoi
            end
                    
            if isempty(self.roiArray)
                roi.id = 1;
            else
                roi.id = self.roiArray{end}.id + 1;
            end
            self.roiArray{end+1} = roi;
        end
        
        function selectRoi(self,roi)
            if isempty(self.selectedRoiArray)
                roiInd = [];
            else
                roiInd = find(cellfun(@(x) x==roi, ...
                                      self.selectedRoiArray));
            end

            % Roi not in self.selectedRoiArray
            if isempty(roiInd)
                self.selectedRoiArray{end+1} = roi;
                ctt = {};
                [ctt{1},ctt{2}] = getTimeTrace(...
                    self.rawMovie,roi,self.defaultResponseOption.offset);
                self.selectedTraceArray{end+1} = ctt;
            else
                disp('ROI already selected!')
            end
        end
        
        function unselectRoi(self,roi)
            roiInd = find(cellfun(@(x) x==roi,self.selectedRoiArray));
            if roiInd
                self.selectedRoiArray(roiInd) = [];
                self.selectedTraceArray(roiInd) = [];
            else
                disp('ROI not selected, cannot unselect!')
            end
        end
        
        function selectSingleRoi(self,roi)
            self.selectedRoiArray = {roi};
            ctt = {};
            [ctt{1},ctt{2}] = getTimeTrace(...
                self.rawMovie,roi,self.responseOption.offset);
            self.selectedTraceArray = {ctt};
        end
        
        function unselectAllRoi(self)
            self.selectedRoiArray = {};
            self.selectedTraceArray = {};
        end
        
        function deleteRoi(self,roi)
            delete(roi);
            self.roiArray = self.roiArray(cellfun(@isvalid, ...
                                                  self.roiArray));
            
            self.selectedRoiArray = self.selectedRoiArray( ...
                cellfun(@isvalid,self.selectedRoiArray));
        end
        
        function roiArray = getRoiArray(self)
            roiArray = self.roiArray;
        end
        
        function addRoiArray(self,roiArray)
            cellfun(@(x) self.addRoi(x),roiArray);
        end

        function saveRoiArray(self,filePath)
            [fileDir,fileName,ext] = fileparts(filePath);
            roiArray = self.roiArray;
            if strcmp(ext,'.mat')
                filePath = fullfile(fileDir,fileName);
                save(filePath,'roiArray');
            end
        end
        
        function loadRoiArray(self,filePath)
            foo = load(filePath);
            roiArray = foo.roiArray;
            self.addRoiArray(roiArray);
        end
    end
end
