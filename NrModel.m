classdef NrModel < handle
    properties (SetObservable)
        filePath
        fileBaseName
        meta
        loadMovieOption
        
        rawMovie
        anatomyMap
        
        responseOption
        responseMap
        masterResponseMap
        localCorrMap
        
        roiArray
        currentRoi
        currentTimeTrace
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
            self.preprocessMovie();
            
            % self.calcAnatomy();
            % self.calcResponse();
            % TODO calcDefaultResponseOption
            self.responseOption = struct('offset',-10,...
                                         'fZeroWindow',[100,200],...
                                         'responseWindow',[400,600]);
            
            self.anatomyMap = zeros(size(self.rawMovie(:,:,1)));
            self.responseMap = zeros(size(self.rawMovie(:,:,1)));
            self.masterResponseMap = zeros(size(self.rawMovie(:,:,1)));
            self.localCorrMap = zeros(size(self.rawMovie(:,:,1)));
            
            self.roiArray = {};
        end
        
        
        function loadMovie(self,filePath)
            startFrame = self.loadMovieOption.startFrame;
            nFrame = self.loadMovieOption.nFrame;
            self.rawMovie = readMovie(filePath,self.meta,nFrame,startFrame);
        end
        
        function preprocessMovie(self)
            nTemplateFrame = 12;
            self.rawMovie = subtractPreampRing(self.rawMovie, nTemplateFrame);
        end
        
        function calcAnatomy(self)
            anatomyMap = mean(self.rawMovie,3);
            self.anatomyMap = anatomyMap;
        end
        
        function responseMap = calcResponse(self,varargin)
        % calculate response map (dF/F)
        % based on parameters defined in self.responseOption
        % or parameters defined in the input argument(s)
            if nargin == 1
                responseOption = self.responseOption;
            elseif nargin == 2
                responseOption = varargin{1};
                self.responseOption = responseOption;
            elseif nargin == 4
                reponseOption = struct('offset',varargin{1}, ...
                                       'fZeroWindow',varargin{2}, ...
                                       'responseWindow', ...
                                       varargin{3});
                self.responseOption = responseOption;
            end
            
            offset = responseOption.offset;
            fZeroWindow = responseOption.fZeroWindow;
            responseWindow = responseOption.responseWindow;
                
            responseMap = dFoverF(self.rawMovie,offset,fZeroWindow, ...
                                  responseWindow);
            self.responseMap = responseMap;
        end
        
        function calcLocalCorrelation(self)
            tilesize = 16;
            self.localCorrMap = computeLocalCorrelation(self.rawMovie,tilesize);
        end
    end
    
    % Methods for ROI-based processing
    methods
        function set.currentRoi(self,roi)
            if isempty(roi)
                self.currentRoi = [];
                self.currentTimeTrace = [];
            elseif isvalid(roi) && isa(roi,'RoiFreehand')
                    RoiInArray = NrModel.isInRoiArray(self,roi);
                    if RoiInArray
                        if RoiInArray > 1
                            warning('Multiple handles to same ROI!')
                        end
                        self.currentRoi = roi;
                        currentTimeTrace = getTimeTrace(...
                            self.rawMovie,roi,self.responseOption.offset);
                        self.currentTimeTrace = currentTimeTrace;
                    else
                        error('ROI not in ROI array!')
                    end
            else
                error('Invalid ROI!')
            end
        end
        
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
        

        % function setCurrentRoiByTag(self,tag)
        %     if strfind(tag,'roi_')
        %         roiArray = self.roiArray;
        %         currentRoiArray = roiArray(cellfun(@(x) strcmp(tag,x.getTag()), ...
        %                                            roiArray));
        %         if length(currentRoiArray) == 1
        %             currentRoi = currentRoiArray{:};
        %             self.currentRoi = currentRoi;
        %         else
        %             error('Tag did not match or more than one ROI matched')
        %         end
        %     else
        %         error(sprintf('Tag %s is wrong format',tag))
        %     end
        % end
        
        function deleteRoi(self,roi)
            if self.currentRoi == roi
                self.currentRoi = [];
            end
            delete(roi);
            roiArray = self.roiArray;
            self.roiArray = roiArray(cellfun(@isvalid,roiArray));
        end
        
        function roiArray = getRoiArray(self)
            roiArray = self.roiArray;
        end
        
        function addRoiArray(self,roiArray)
            cellfun(@(x) self.addRoi(x),roiArray);
        end

    end
    
    methods(Static)
        function result = isInRoiArray(self,roi)
            roiArray = self.roiArray;
            existArray = cellfun(@(x) x == roi,roiArray);
            result = sum(existArray);
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
