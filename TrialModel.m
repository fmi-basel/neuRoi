classdef TrialModel < handle
    properties
        filePath
        loadMovieOption
        preprocessOption
        motionCorrOption
        
        yxShift
        intensityOffset

        fileBaseName
        tag
        name
        sourceFileIdx
        
        
        meta
        rawMovie
        
        roiArray
        templateAnatomy
        resultDir
        roiFilePath
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
        MAX_N_ROI = 400
    end
    
    events
        mapArrayLengthChanged
        mapUpdated
        
        roiAdded
        roiDeleted
        roiUpdated
        roiArrayReplaced
        roiTagChanged
        
        roiSelected
        roiUnSelected
        roiSelectionCleared
        
        trialDeleted
    end
    
    methods
        function self = TrialModel(filePath,varargin)
            pa = inputParser;
            addRequired(pa,'filePath',@ischar);
            addParameter(pa,'zrange',[1 inf], @ismatrix);
            addParameter(pa,'nFramePerStep',1)
            addParameter(pa,'process',false);
            addParameter(pa,'noSignalWindow',[1 12]);
            addParameter(pa,'motionCorr',false);
            addParameter(pa,'motionCorrDir','');
            addParameter(pa,'mcNFramePerStep',1);
            addParameter(pa,'frameRate',1);
            validYxShift = @(x) isequal(size(x),[1 2]);
            addParameter(pa,'yxShift',[0 0],validYxShift);
            addParameter(pa,'intensityOffset',0);
            addParameter(pa,'resultDir',pwd());
            addParameter(pa,'syncTimeTrace',false);
            
            parse(pa,filePath,varargin{:})
            pr = pa.Results;
            
            self.filePath = pr.filePath;
            self.loadMovieOption = struct('zrange',pr.zrange,...
                                          'nFramePerStep', ...
                                          pr.nFramePerStep);
            self.preprocessOption = struct('process',pr.process,...
                                           'noSignalWindow', ...
                                           pr.noSignalWindow);
            
            self.motionCorrOption = struct('motionCorr',pr.motionCorr,...
                                           'motionCorrDir',pr.motionCorrDir,...
                                           'nFramePerStep',pr.mcNFramePerStep);
            
            if ~exist(self.filePath,'file')
                error(sprintf('The movie file %s does not exist!',self.filePath))
                % [~,self.fileBaseName,~] = fileparts(filePath);
                % self.name = self.fileBaseName;
                % self.meta = struct('width',12,...
                %                    'height',10,...
                %                    'totalNFrame',5);
                % self.rawMovie = rand(self.meta.height,...
                %                      self.meta.width,...
                %                      self.meta.totalNFrame);
            else
                [~,self.fileBaseName,~] = fileparts(self.filePath);
                self.name = ...
                    TrialModel.getDefaultTrialName(self.fileBaseName,pr.zrange,pr.nFramePerStep);
                
                % Read data from file
                self.meta = movieFunc.readMeta(self.filePath);
                self.loadMovie(self.filePath,self.loadMovieOption);
                
                if self.preprocessOption.process
                    disp('Processing image: no signal window:')
                    disp(self.preprocessOption.noSignalWindow)
                    self.preprocessMovie(self.preprocessOption.noSignalWindow);
                end
                
                if self.motionCorrOption.motionCorr
                    offsetYxFileName = sprintf('%s_%s.mat','mcOffsetYx',self.fileBaseName);
                    self.motionCorrOption.offsetYxFile = ...
                        fullfile(self.motionCorrOption.motionCorrDir,offsetYxFileName);
                    try
                        foo = load(self.motionCorrOption.offsetYxFile);
                    catch ME
                        disp(['Error occurred when loading motion ' ...
                              'correction offset.'])
                        rethrow(ME)
                    end
                    
                    self.motionCorrOption.offsetYx = foo.offsetYx;
                    self.correctMotionYx(self.motionCorrOption.offsetYx,...
                                         self.motionCorrOption.nFramePerStep);
                end
                
                if pr.resultDir
                    self.resultDir = pr.resultDir;
                end
            end
            
            % User specified frame rate
            self.meta.frameRate = pr.frameRate;
            
            % Intensity offset for calculating dF/F
            self.intensityOffset = pr.intensityOffset;
            
            % shift movie in x and y axis
            self.yxShift = [0 0];
            if any(pr.yxShift)
                self.shiftMovieYx(pr.yxShift)
            end

            
            % Initialize map array
            self.mapArray = {};

            % Calculate anatomy map
            self.calculateAndAddNewMap('anatomy');

            % Whether to syncronize time trace while selecting ROIs
            self.syncTimeTrace = pr.syncTimeTrace;
            
            % Initialize ROI array
            self.roiVisible = true;
            self.roiArray = RoiFreehand.empty();
            
        end
        
        function loadMovie(self,filePath,loadMovieOption)
            if self.loadMovieOption.zrange(2) == inf
                self.loadMovieOption.zrange(2) = self.meta.totalNFrame;
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
            self.rawMovie = movieFunc.subtractPreampRing(self.rawMovie,noSignalWindow);
        end
        
        function correctMotionYx(self,offsetYx,nFramePerStep)
        % nFramePerStep: the step to read the offset values for
        % each frame in the raw movie
            disp('Start motion correction...')
            for k = 1:size(self.rawMovie,3)
                osIdx = 1+nFramePerStep*(k-1);
                if mod(k,100) == 0; disp(k/size(self.rawMovie,3)); end
                self.rawMovie(:,:,k) = circshift(self.rawMovie(:,:,k),[- ...
                                    offsetYx(1,osIdx),-offsetYx(2,osIdx)]);
            end
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
        
        function mapInd = findMapByType(self,mapType)
            currentMap = self.mapArray{self.currentMapInd};
            if strcmp(currentMap.type,mapType)
                mapInd = self.currentMapInd;
            else
                mapInd = find(cellfun(@(x) strcmp(x.type,mapType), ...
                                      self.mapArray));
                if ~length(mapInd)
                    msg = sprintf(['No map of type %s found! You can ' ...
                                   'create a new map of this type ' ...
                                   'by adding map.'],mapType);
                    error('TrialModel:mapTypeError',msg)
                end
                mapInd = mapInd(1);
            end
        end
        
        function findAndUpdateMap(self,mapType,mapOption)
            mapInd = findMapByType(self,mapType)
            self.updateMap(mapInd,mapOption);
            if mapInd ~= self.currentMapInd
                self.selectMap(mapInd);
            end
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
        
        function importMap(self,mapFilePath)
            map.type = 'import';
            [~,map.option.fileName,~] = fileparts(mapFilePath);
            
            TifLink = Tiff(mapFilePath, 'r');
            map.data = TifLink.read();
            self.addMap(map);
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
        % beginning and end number of frames used to calculate the
        % anatomy.
            if nargin == 1
                defaultNFrameLimit = [1 size(self.rawMovie,3)];
                nFrameLimit = defaultNFrameLimit;
                sigma = 0;
            elseif nargin == 2
                mopt = varargin{1};
                nFrameLimit = mopt.nFrameLimit;
                sigma = mopt.sigma;
            else
                error('Wrong usage!')
                help TrialModel.calcAnatomy
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
            if sigma
                mapData = conv2(mapData,fspecial('gaussian',[3 3], sigma),'same');
                mapOption.sigma = sigma;
            end
            mapOption.nFrameLimit = nFrameLimit;
        end
        
        function vecFrame = convertFromSecToFrame(self,vecSec)
            frameRate = self.meta.frameRate;
            vecFrame = round(vecSec * frameRate);
        end
        
        function [mapData,mapOption] = calcResponse(self,varargin)
        % Method to calculate response map (dF/F)
        % Usage: 
        % mymodel.calcResponse(offset,fZeroWindow,responseWindow) 
        % mymodel.calcResponse(mapOption)
        % mapOption is a structure that contains
        % offset,fZeroWindow,responseWindow in its field
        % Units of fZeroWindow and responseWindow are in second
            if nargin == 2
                mapOption = varargin{1};
                offset = mapOption.offset;
                fZeroWindow = mapOption.fZeroWindow;
                responseWindow = mapOption.responseWindow;
            elseif nargin == 4
                offset = varargin{1};
                fZeroWindow = varargin{2};
                responseWindow = varargin{3};
            else
                error('Wrong usage!')
                help TrialModel.calcResponse
            end
            
            % Convert unit of windows from second to frame number
            fZeroWindowFrame = self.convertFromSecToFrame(fZeroWindow);
            responseWindowFrame = ...
                self.convertFromSecToFrame(responseWindow);
            
            % Validate window parameters
            nf = self.getNFrameRawMovie();
            wdMinMax = [1,nf];
            fres=TrialModel.isNotValidWindowValue(fZeroWindowFrame,...
                                                  wdMinMax,...
                                                  'fZeroWindow');
            rres=TrialModel.isNotValidWindowValue(responseWindowFrame,...
                                                  wdMinMax,...
                                                  'responseWindow');
            if ~fres & ~rres
                mapData = movieFunc.dFoverF(self.rawMovie,offset, ...
                                            fZeroWindowFrame, ...
                                            responseWindowFrame);
            end
        end
        
        function [mapData,mapOption]=calcResponseMax(self,varargin)
            if nargin == 2
                mapOption = varargin{1};
                offset = mapOption.offset;
                fZeroWindow = mapOption.fZeroWindow;
                slidingWindowSize = mapOption.slidingWindowSize;
            elseif nargin == 4
		offset = varargin{1};
                fZeroWindow = varargin{2};
		slidingWindowSize = varargin{3};
            else
                error('Wrong Usage!')
            end
            
            % Convert unit of window from second to frame number
            fZeroWindowFrame = ...
                self.convertFromSecToFrame(fZeroWindow);
            slidingWindowSizeFrame = self.convertFromSecToFrame(slidingWindowSize);
            
            % Validate window parameter
            nf = self.getNFrameRawMovie();
            wdMinMax = [1,nf];
            fres=TrialModel.isNotValidWindowValue(fZeroWindowFrame,...
                                                  wdMinMax,...
                                                  'fZeroWindow');

            if ~fres
                mapData = movieFunc.dFoverFMax(self.rawMovie,offset,...
                                               fZeroWindowFrame,...
                                               slidingWindowSizeFrame);
            end
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
                tagArray = self.getAllRoiTag();
                roi.tag = max(tagArray)+1;
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
        
        function tagArray = getAllRoiTag(self)
            tagArray = arrayfun(@(x) x.tag, self.roiArray);
        end
        
        function selectAllRoi(self)
            tagArray = self.getAllRoiTag();
            self.unselectAllRoi();
            self.selectedRoiTagArray = tagArray;
            for k=1:length(tagArray)
                tag = tagArray(k);
                notify(self,'roiSelected',NrEvent.RoiEvent(tag));
            end
            disp('All Rois selected')
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
                   NrEvent.RoiUpdatedEvent([self.roiArray(ind)]));
            disp(sprintf('Roi #%d updated',tag))
        end
        
        function changeRoiTag(self,oldTag,newTag)
            ind = self.findRoiByTag(oldTag);
            oldRoi = self.roiArray(ind);
            tagArray = self.getAllRoiTag();
            if ismember(newTag,tagArray)
                error(['New tag cannot be assigned! The tag is ' ...
                       'already used by another ROI.'])
            else
                oldRoi.tag = newTag;
                self.roiArray(ind) = oldRoi;
                notify(self,'roiTagChanged', ...
                NrEvent.RoiTagChangedEvent(oldTag,newTag));
                disp(sprintf('Roi #%d changed to #%d',oldTag,newTag))
                if ismember(oldTag,self.selectedRoiTagArray)
                    idx = find(self.selectedRoiTagArray,oldTag);
                    self.selectedRoiTagArray(idx) = newTag;
                end
            end
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
            ind = self.findMapByType('anatomy');
            templateAnatomy = self.mapArray{ind}.data;
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
            if isfield(foo,'templateAnatomy')
                self.templateAnatomy = foo.templateAnatomy;
            end
        end
        
        function matchRoiPos(self,roiTagArray,windowSize)
            fitGauss = 1;
            normFlag = 1;
            roiIndArray = self.findRoiByTagArray(roiTagArray);
            mapInd = self.findMapByType('anatomy');
            inputMap = self.mapArray{mapInd}.data;
            for ind = roiIndArray
                self.roiArray(ind).matchPos(inputMap, ...
                                            self.templateAnatomy,...
                                            windowSize,...
                                            fitGauss,...
                                            normFlag)
            end
            notify(self,'roiUpdated', ...
                   NrEvent.RoiUpdatedEvent(self.roiArray(roiIndArray)));
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
        function vecSec = convertFromFrameToSec(self,vecFrame)
            frameRate = self.meta.frameRate;
            vecSec = vecFrame/frameRate;
        end
        function [timeTrace,timeVec] = getTimeTraceByTag(self,tag,varargin)
            if nargin == 2
                sm = 0;
            elseif nargin == 3
                sm = varargin{1};
            end

            fZeroPercent = 0.5;
            ind = self.findRoiByTag(tag);
            roi = self.roiArray(ind);
            timeTraceRaw = TrialModel.getTimeTrace(self.rawMovie,roi);
            timeTrace = TrialModel.getTimeTraceDf(timeTraceRaw, ...
                                          'intensityOffset',self.intensityOffset, ...
                                          'fZeroPercent',fZeroPercent,'sm',sm);
            timeVec = self.convertFromFrameToSec(1:length(timeTrace));
        end
        
        function [timeTraceMat,roiArray] = ...
                extractTimeTraceMat(self,varargin)
            roiArray = self.roiArray;
            nRoi = length(roiArray);
            timeTraceMat = zeros(nRoi,size(self.rawMovie,3));
            for k=1:nRoi
                roi = roiArray(k);
                timeTraceRaw = TrialModel.getTimeTrace(self.rawMovie,roi);
                timeTraceMat(k,:) = timeTraceRaw;
            end
        end
        
        
    end
    
    methods
        function delete(self)
            notify(self,'trialDeleted');
        end
    end
    
    methods (Static)        
        function timeTraceRaw = getTimeTrace(rawMovie,roi,varargin)
        % GETTIMETRACE get raw time trace within a ROI
        % from the input raw movie
        % Usage: timeTraceRaw = getTimeTrace(rawMovie,roi)
            mask = roi.createMask;
            [maskIndX maskIndY] = find(mask==1);
            roiMovie = rawMovie(maskIndX,maskIndY,:);
            timeTraceRaw = squeeze(mean(mean(roiMovie,1),2));
            % timeTraceRaw = timeTraceRaw(:);
        end
        

        function timeTraceDf = getTimeTraceDf(timeTraceRaw,varargin)
            pa = inputParser;
            addParameter(pa,'intensityOffset',0)
            addParameter(pa,'fZeroWindow',0)
            addParameter(pa,'fZeroPercent',0.5)
            addParameter(pa,'sm',0)
            parse(pa,varargin{:})
            pr = pa.Results;
            
            if pr.fZeroWindow == 0
                pr.fZeroWindow = 10:(length(timeTraceRaw)-10);
            end
            
            timeTraceFg = timeTraceRaw - pr.intensityOffset;
            if pr.sm
                % TODO change the smooth function to gaussian filter!!
                timeTraceSm = smooth(timeTraceFg,pr.sm);
                fZero = quantile(timeTraceSm(pr.fZeroWindow),pr.fZeroPercent);
                timeTraceDf = (timeTraceSm - fZero) / fZero;
            else
                fZero = quantile(timeTraceFg(pr.fZeroWindow),pr.fZeroPercent);
                timeTraceDf = (timeTraceFg - fZero) / fZero;
            end
        end
        
        
        function dfName = getDefaultTrialName(fileBaseName,zrange, ...
                                                           nFramePerStep)
            if isnumeric(zrange)
                dfName = sprintf('%s_frame%dto%dby%d',fileBaseName, ...
                             zrange(1),zrange(2),nFramePerStep);
            elseif strcmp(zrange,'all')
                dfName = sprintf('%s_frame_all_by%d',fileBaseName, ...
                                 nFramePerStep);
            else
                dfName = fileBaseName;
            end
            
        end
                

        function result = isNotValidWindowValue(wdw,wdMinMax,wdName)
            result = 0;
            if wdw(1) > wdw(2)
                result = 1;
                msg = 'Start value should be smaller than end value!';
            end
            
            if wdw(1) < wdMinMax(1)
                result = 2;
                msg='Start value should be larger or equal to min value!';
            end

            if wdw(2) > wdMinMax(2)
                result = 3;
                msg='End value should be less or equal to max value!';
            end
            
            if result
                msgId = 'TrialModel:windowValueError';
                msg = sprintf('%s: %s',wdName,msg);
                errorStruct.message = msg;
                errorStruct.identifier = msgId;
                error(errorStruct)
            end
        end
    end
end
