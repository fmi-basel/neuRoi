classdef TrialModel < baseTrial.BaseTrialModel
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
        mapSize
        rawMovie
        
        roiDir
        roiFilePath
        
        jroiDir
        maskDir

        setupMode %1=SetupA; 3=SetupC/VR
        loadMapFromFile %Mainly for SetupC mode
        loadedMapsize %needed because setupC doesn't load rawmovie when opening trial
        
        MAX_NUM_MAPS = 6
        
        previousRoiArr
    end
        
    properties (Access = private)
        mapArray
        roiTagMax
    end
    
    properties (SetObservable)
        currentMapInd
        roiVisible
        selectedRoiTagArray
        syncTimeTrace
    end
    
    events
        mapAdded
        mapUpdated
        trialDeleted
        roiGroupUpdated
        currentRoiGroupSet
        assignedRoisToGroup
    end
    
    methods
        function self = TrialModel(varargin)
            pa = inputParser;
            addParameter(pa,'filePath','', @ischar);
            addParameter(pa,'mockMovie',struct([]), @isstruct);
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
            addParameter(pa,'roiDir',pwd());
            addParameter(pa,'jroiDir',pwd());
            addParameter(pa,'maskDir',pwd());
            addParameter(pa,'syncTimeTrace',false);
            addParameter(pa,'setupMode',1);
            addParameter(pa,'loadMapFromFile',false);
            addParameter(pa,'loadedMapsize',false);
            
            parse(pa,varargin{:})
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
            
            if isempty(self.filePath)
                if ~isempty(pr.mockMovie)
                    self.name = pr.mockMovie.name;
                    self.meta = pr.mockMovie.meta;
                    self.rawMovie = pr.mockMovie.rawMovie;
                else
                    error('Please provide a valid mock movie.')
                end
            else
                if ~exist(self.filePath,'file')
                    msg = sprintf('The movie file %s does not exist!',self.filePath)
                    error(msg)
                end
                [~,self.fileBaseName,fileExtension] = fileparts(self.filePath);
               
                %Check if file is Tiff(SetupA) or .mat(SetupC)
                if fileExtension==".tif"
                    self.name = ...
                    trialMvc.TrialModel.getDefaultTrialName(self.fileBaseName,pr.zrange,pr.nFramePerStep);
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
                elseif fileExtension==".mat"
                     self.name =self.fileBaseName;
                    if pr.loadMapFromFile
                    else
                    end
                end
                
                if pr.roiDir
                    self.roiDir = pr.roiDir;
                end
            
                if pr.jroiDir
                    self.jroiDir = pr.jroiDir;
                end
                
                if pr.maskDir
                    self.maskDir = pr.maskDir;
                end

            end

            if pr.loadedMapsize
                self.loadedMapsize=pr.loadedMapsize;
            else
                self.loadedMapsize=[0 0];
            end

            if pr.setupMode
                self.setupMode = pr.setupMode;
            end

            self.loadMapFromFile = pr.loadMapFromFile;
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
            
            if ~self.loadMapFromFile
                % Calculate anatomy map
                self.calculateAndAddNewMap('anatomy');
            end

            % Whether to syncronize time trace while selecting ROIs
            self.syncTimeTrace = pr.syncTimeTrace;
            
            % Initialize ROI array
            self.mapSize = self.getMapSize();
            self.roiArr = roiFunc.RoiArray('imageSize', self.mapSize);
            self.roiVisible = true;
        end
        
        function removeRoiOverlap(self)
            RoiMask=self.CreateMaskFromRoiArrayNoOverlap();
            NewRoiArray=self.CreateRoiArrayFromMask(RoiMask);
            self.roiArray=NewRoiArray;
            tagArray = self.getAllRoiTag();
            self.roiTagMax = max(tagArray);
            notify(self,'roiArrayReplaced');
        end

        function NewRoiArray=CreateRoiArrayFromMask(self,OutputMask)

            NewRoiArray = RoiFreehand.empty();
            for j=1:max(max(OutputMask))
                [col,row]=find(OutputMask==j); %not needed anymore
                if ~isempty(row)
                    %from TrialModel
%                      poly = roiFunc.mask2poly(OutputMask==j);
                     mask=OutputMask==j;
                     BW3 = imresize(mask,3,'nearest');
                     B3 = bwboundaries(BW3);
                     B3 = B3{1};
                
                     poly.X = ((B3(:,2) + 1)/3)';
                     poly.Y = ((B3(:,1) + 1)/3)';
                
                     poly.Length=length(poly.X);
                     poly.Fill=1;

                     if length(poly) > 1
                         % TODO If the mask corresponds multiple polygon,
                         % for simplicity,
                         % take the largest polygon
                         warning(sprintf('ROI %d has multiple components, only taking the largest one.',j))
                         pidx = find([poly.Length] == max([poly.Length]));
                         poly = poly(pidx);
                     end
                     xposition=poly.X;
                     yposition=poly.Y;
                     position = [xposition',yposition'];
                     newroi = RoiFreehand(position);
    
                     %newroi = RoiFreehand([row,col]); old and wrong- need
                     %contour of roi, not all pixel values
                     newroi.tag = j;
                     NewRoiArray(end+1) = newroi;
                     %TransformedMasks(i,j+1)=newroi;
                else
    %                  tempString=strcat("lost roi detected: roi number: " ,int2str(j)," in trial: ", int2str(i));
    %                  disp(tempString);
                end
            end

        end

        function RoiMap=CreateMaskFromRoiArrayNoOverlap(self)
            
            width =self.loadedMapsize(1);
            height=self.loadedMapsize(2);

            nRoi= length(self.roiArray);

            RoiMap = zeros( width,height, 'uint16');
        
            for i=1:nRoi
                newroi=self.roiArray(i);
                binaryImage =double(newroi.tag)* newroi.createMask([ width,height]);
                RoiMap= RoiMap+ uint16(binaryImage);
                RoiMap((RoiMap>newroi.tag))=0;
            end
        end

        function loadMatAsRawMovie(self,filePath)
            %Specific for SetupC data: Raw file is a .mat file containing
            %a variable called stack 
            TempData= load(filePath);
            self.rawMovie=TempData.stack;
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
            if self.loadMapFromFile
                mapSize=self.loadedMapsize;
            else
                mapSize = size(self.rawMovie(:,:,1));
            end
        end
        
        function map = getMapByInd(self,ind)
            map = self.mapArray{ind};
        end
        
        function mapArrayLen = getMapArrayLength(self)
            mapArrayLen = length(self.mapArray);
        end
        
        function map = getCurrentMap(self)
            %if needed in case no map was calculated
            if ~isempty(self.currentMapInd)
                map = self.mapArray{self.currentMapInd};
            else
                map=null(1);
            end
        end
        
        function map = calculateAndAddNewMap(self,mapType,varargin)
            if isempty(self.rawMovie)
               if self.setupMode==3 %SetupC
               self.loadMatAsRawMovie(self.filePath);
               else
                   %TODO but unlikly to happen or be useful
               end
            end
            map.type = mapType;
            [map.data,map.option] = self.calculateMap(mapType,varargin{:});
            self.addMap(map);
        end

        function LoadAndAddMapFromFile(self, mapFile)
            %load mapstruct; contain map itself plus options
            newmapStruct = load(mapFile);
            newmapFields = fields(newmapStruct(1));
            [containOptions, newmmapOptionsIndex]=ismember('options',newmapFields);
            if containOptions
                newmmapOptions=getfield(newmapStruct,'options');
                newmapFields(newmmapOptionsIndex)=[];
            else
                newmmapOptions.options=strcat('No Options available. Name of the file:',{' '}, string(newmapFields{1}));
            end
            newmap.option=newmmapOptions;
            newmap.data=getfield(newmapStruct,newmapFields{1});
            if strcmp( newmapFields{1}, 'anatomy')
                tempimage=(newmap.data-min(min(newmap.data)))/(max(max(newmap.data))-min(min(newmap.data)));
                tempimage=adapthisteq(tempimage,'NumTiles',[16 16]);
                %tempimage=ind2rgb(uint8(tempimage*255),gray(256));
                newmap.data=tempimage;
            end
            newmap.type=newmapFields{1};
            self.loadedMapsize=size(newmap.data);
            
            self.addMap(newmap);
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
                    error('trialMvc.TrialModel:mapTypeError',msg)
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
        
        function selectMapType(self, ind)
        % SELECTMAPTYPE
        % This is a function written to be compatible to BaseTrialController
        % Should be optimized in the future
            self.selectMap(ind);
        end
        
        function addMap(self,newMap)
            self.mapArray{end+1} = newMap;
            mapArrayLen = self.getMapArrayLength();
            self.selectMap(mapArrayLen);
            notify(self,'mapAdded');
        end
        
        % function deleteMap(self,mapInd)
        %     self.mapArray(mapInd) = [];
        %     notify(self,'mapArrayLengthChanged');
        % end
        
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
        
        function saveContrastLim(self,contrastLim)
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
              case 'SetupCAnatomy'
                   [mapData,mapOption] = self.calcAnatomy();
              case 'SetupCResponse'
                   [mapData,mapOption] = self.calcSetupCResponse(varargin{:});
              case 'SetupCResponseMax'
                   [mapData,mapOption] = self.calcSetupCResponseMax(varargin{:});
              case 'SetupCCorr'
                   [mapData,mapOption] = self.calcSetupCCorr(varargin{:});
            end
        end
        
        %SetupCTab calculations
        function [mapData,mapOption] = calcSetupCCorr(self, ...
                                                            varargin)
            if nargin == 2
                if isstruct(varargin{1})
                    mapOption = varargin{1};
                    tileSize=mapOption.tileSize;
                    skippingNumber=mapOption.skipping;
                else
                    mapOption.tileSize = varargin{1};
                    skippingNumber=0;
                end
            elseif nargin == 3
                tileSize = varargin{1};
                skippingNumber = varargin{2};
            else
                error('Wrong Usage!');
            end
            if skippingNumber>0
                subRawMovie=self.rawMovie(:,:,1:skippingNumber:end);
            else
                subRawMovie=self.rawMovie;
            end

            mapData = movieFunc.computeLocalCorrelation(subRawMovie,tileSize);
        end
        

        function [mapData,mapOption]=calcSetupCResponseMax(self,varargin)
            if nargin == 2
                mapOption = varargin{1};
                offset = mapOption.offset;
                lowerPercentile = mapOption.lowerPercentile;
                skippingNumber = mapOption.skipping;
                slidingWindowSize = mapOption.slidingWindowSize;
            elseif nargin == 5
		        offset = varargin{1};
		        slidingWindowSize = varargin{2};
                lowerPercentile = varargin{3};
                skippingNumber = varargin{4};
            else
                error('Wrong Usage!')
            end
            
            % Convert unit of window from second to frame number
            slidingWindowSizeFrame = self.convertFromSecToFrame(slidingWindowSize);
        
            mapData = movieFunc.dFoverFMax(self.rawMovie,offset,...
                                           [],...
                                           slidingWindowSizeFrame,...
                                           lowerPercentile,...
                                           skippingNumber);
            
        end


        function [mapData,mapOption] = calcSetupCResponse(self,varargin)
             if nargin == 2
                mapOption = varargin{1};
                offset = mapOption.offset;
                lowerPercentile = mapOption.lowerPercentile;
                skippingNumber = mapOption.skipping;
            elseif nargin == 4
                offset = varargin{1};
                lowerPercentile = varargin{2};
                skippingNumber = varargin{3};
            else
                error('Wrong usage!')
                help trialMvc.TrialModel.calcResponse
            end
            mapData=movieFunc.dFoverF(self.rawMovie,offset,[],[],lowerPercentile,skippingNumber);
        end

        function [mapData,mapOption] = calcSetupCAnatomy(self,varargin)
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
                help trialMvc.TrialModel.calcSetupCAnatomy
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
                help trialMvc.TrialModel.calcAnatomy
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
                help trialMvc.TrialModel.calcResponse
            end
            
            % Convert unit of windows from second to frame number
            fZeroWindowFrame = self.convertFromSecToFrame(fZeroWindow);
            responseWindowFrame = ...
                self.convertFromSecToFrame(responseWindow);
            
            % Validate window parameters
            nf = self.getNFrameRawMovie();
            wdMinMax = [1,nf];
            fres=trialMvc.TrialModel.isNotValidWindowValue(fZeroWindowFrame,...
                                                  wdMinMax,...
                                                  'fZeroWindow');
            rres=trialMvc.TrialModel.isNotValidWindowValue(responseWindowFrame,...
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
            fres=trialMvc.TrialModel.isNotValidWindowValue(fZeroWindowFrame,...
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
        
        function mapDataList = getMapDataList(self, mapTypeList)
            nMap = length(mapTypeList);
            mapIndList = cellfun(@(x) self.findMapByType(x), mapTypeList,...
                                 'UniformOutput', false);
            mapDataList = uint8(zeros([self.getMapSize(), nMap]));
            for k=1:nMap
                mapType = mapTypeList{k};
                mapInd = mapIndList{k};
                mapp = self.getMapByInd(mapInd);
                mapData = movieFunc.convertToUint(mapp.data);
                mapDataList(:,:,k) = mapData;
            end
        end
        
        % Methods for ROIs
        function tag = getNewRoiTag(self)
            if isempty(self.roiArr.getTagList())
                tag = 1;
            else
                tag = max(self.roiArr.getTagList()) + 1;
            end
        end
        
        function addRoi(self, roi)
            roi.tag = self.getNewRoiTag();
            self.roiArr.addRoi(roi, self.roiArr.currentGroupName);
            notify(self, 'roiAdded')
        end
        
        function saveRoiArr(self,filePath)
            roiArr = self.roiArr;
            save(filePath,'roiArr');
        end
        
        function replaceRoiArr(self, roiArr)
            self.roiArr = roiArr;
            notify(self, 'roiArrReplaced')
        end
        
        function loadRoiArr(self,filePath)
            roiArr = roiFunc.loadRoiArr(filePath, self.getMapSize());
            self.replaceRoiArr(roiArr);
        end
        
        function importRoisFromMask(self,maskImg)
            roiArr = roiFunc.RoiArray('maskImg', maskImg);
            self.replaceRoiArr(roiArr)
        end
        
        function importRoisFromMaskFile(self,filePath)
            maskImg = movieFunc.readTiff(filePath);
            % Make sure the size only has length of 2

            if length(size(maskImg)) > 2
                % Remove the dimensions that are singleton
                maskImg = squeeze(maskImg);
            end
            if ~isequal(size(maskImg),self.getMapSize())
                error(['Image size of mask does not match the map size ' ...
                       '(pixel size in x and y)!'])
            end
            self.importRoisFromMask(maskImg)
        end
        
        function importRoisFromImageJ(self,filePath)
            [jroiArray] = roiFunc.ReadImageJROI(filePath);
            roiArray = roiFunc.convertFromImageJRoi(jroiArray);
            self.insertRoiArray(roiArray,'replace');
        end
        

        % Methods for ROI group
        function addRoiGroup(self, groupName)
            self.roiArr.addGroup(groupName)
            notify(self, 'roiGroupUpdated')
        end

        function renameCurrentRoiGroup(self, newGroupName)
            self.roiArr.renameGroup(self.roiArr.currentGroupName,...
                                    newGroupName)
            notify(self, 'roiGroupUpdated')
        end
        
        function setCurrentRoiGroup(self, groupName)
            self.roiArr.currentGroupName = groupName;
            notify(self, 'currentRoiGroupSet')
        end
        
        function assignRoiToCurrentGroup(self, tag)
            roi = self.roiArr.assignRoiToCurrentGroup(tag);
            notify(self,'assignedRoisToGroup', NrEvent.AssignedRoisToGroupEvent(roi));
        end

        function assignSelectedRoisToCurrentGroup(self)
            rois = self.roiArr.assignSelectedRoisToCurrentGroup();
            notify(self,'assignedRoisToGroup', NrEvent.AssignedRoisToGroupEvent(rois));
        end

        % Methods for contrast
        function dataLim = getDataLim(self)
            map = self.getCurrentMap();
            dataLim = helper.minMax(map.data);
            sn = 10000*eps; % a small number
            dataLim(2) = dataLim(2) + sn;
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
            roi = self.roiArr.getRoi(tag);
            timeTraceRaw = trialMvc.TrialModel.getTimeTrace(self.rawMovie,roi);
            timeTrace = trialMvc.TrialModel.getTimeTraceDf(timeTraceRaw, ...
                                          'intensityOffset',self.intensityOffset, ...
                                          'fZeroPercent',fZeroPercent,'sm',sm);
            timeVec = self.convertFromFrameToSec(1:length(timeTrace));
        end
        
        function [timeTraceMat,roiArr] = ...
                extractTimeTraceMat(self,varargin)
            roiArr = self.roiArr;
            roiList = roiArr.getRoiList;
            nRoi = length(roiList);
            timeTraceMat = zeros(nRoi,size(self.rawMovie,3));
            for k=1:nRoi
                roi = roiList(k);
                timeTraceRaw = trialMvc.TrialModel.getTimeTrace(self.rawMovie,roi);
                timeTraceMat(k,:) = timeTraceRaw;
            end
        end
        
        
    end
    
    % For undo
    methods
        function recordState(self)
            self.previousRoiArr = self.roiArr.copy();
        end
        
        function restoreState(self)
            self.roiArr = self.previousRoiArr;
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
            mapSize = size(rawMovie(:,:,1));
            maskIndX = roi.position(:,1);
            maskIndY = roi.position(:,2);
            roiMovie = rawMovie(maskIndY,maskIndX,:);
            timeTraceRaw = squeeze(mean(mean(roiMovie,1),2));
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
                msgId = 'trialMvc.TrialModel:windowValueError';
                msg = sprintf('%s: %s',wdName,msg);
                errorStruct.message = msg;
                errorStruct.identifier = msgId;
                error(errorStruct)
            end
        end
    end
end
