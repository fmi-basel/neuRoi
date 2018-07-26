classdef NrModel < handle
% NRMODEL the class in neuRoi that stores data and does computation
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
    
    methods
        function self = NrModel(filePath,varargin)
            if nargin == 1
                loadMovieOption = struct('startFrame', 50, ...
                                         'nFrame', 900);
            elseif nargin == 2
                loadMovieOption = varargin{1};
            else
                error(['Usage: NrModel(filePath,' ...
                       '[loadMovieOption])']);
            end
            self.filePath = filePath;
            [~,self.fileBaseName,~] = fileparts(filePath);
            self.meta = readMeta(filePath);
            
            self.loadMovieOption = loadMovieOption;
            self.loadMovie(filePath);
            
            self.yxShift = [0 0];
            
            self.noSignalWindow = [1, 12];
            self.preprocessMovie();
            
            % TODO calcDefaultResponseOption
            self.defaultResponseOption = self.calcDefaultResponseOption();
            
            
            % Initialize map array
            self.mapArray = {};
            
            % Initialize ROI array
            self.roiArray = {};
        end
        
        
        function loadMovie(self,filePath)
            if isempty(self.loadMovieOption)
                self.loadMovieOption.startFrame = 1;
                self.loadMovieOption.nFrame = self.meta.numberframes;
            end
            startFrame = self.loadMovieOption.startFrame;
            nFrame = self.loadMovieOption.nFrame;
            self.rawMovie = readMovie(filePath,self.meta,nFrame,startFrame);
        end
        
        function preprocessMovie(self)
            self.rawMovie = subtractPreampRing(self.rawMovie,self.noSignalWindow);
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
        
        function [mapData,mapOption] = calculateMap(self,mapType,varargin)
            switch mapType
              case 'anatomy'
                [mapData,mapOption] = self.calcAnatomy(varargin{:});
              case 'response'
                [mapData,mapOption] = self.calcResponse(varargin{:});
              % case 'responseMax'
              %   newMap = self.calcResponseMax(varargin{:});
              % case 'localCorrelation'
              %   newMap = self.calcLocalCorrelation(varargin{:});
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
        % based on parameters defined in self.mapOption
        % or parameters defined in the input argument(s)
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
        
        function responseMaxMap = calcResponseMax(self)
        end
        
        function calcLocalCorrelation(self)
            tilesize = 16;
            self.localCorrMap = computeLocalCorrelation(self.rawMovie,tilesize);
        end
    end
    
    % Methods for ROI-based processing
    methods
        function addRoi(self,varargin)
        % add ROI to ROI array
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

    end
    
    methods(Static)
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
