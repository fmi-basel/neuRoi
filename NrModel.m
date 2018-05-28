classdef NrModel < handle
    properties (SetObservable)
        filePath
        fileBaseName
        meta
        rawMovie
        anatomyMap
        responseMap
        masterResponseMap
        localCorrMap
        displayState
        stateArray
        
        roiArray
        currentRoi
        currentTimeTrace
        % roiMap
        % timeTraceArray
    end
    
    methods
        function self = NrModel(filePath)
            self.filePath = filePath;
            [~,self.fileBaseName,~] = fileparts(filePath);
            self.loadMovie(filePath);
            self.preprocessMovie();
            self.calcAnatomy();
            self.calcResponse;
            self.localCorrMap = zeros(size(self.rawMovie(:,:,1)));
            self.stateArray = {'anatomy','response', ...
                               'masterResponse','localCorr'};
            self.displayState = self.stateArray{1};
            
            self.roiArray = {};
        end
        
        function loadMovie(self,filePath)
            meta = readMeta(filePath);
            
            nPlane = 1;
            meta.framerate = meta.framerate/nPlane;
            self.meta = meta;
            
            startFrame = 50;
            nFrame = 20;
            planeNum = 1;
            
            self.rawMovie = readMovie(filePath,self.meta,nFrame,startFrame,nPlane,planeNum);
        end
        
        function preprocessMovie(self)
            nTemplateFrame = 12;
            self.rawMovie = subtractPreampRing(self.rawMovie, nTemplateFrame);
        end
        
        function calcAnatomy(self)
            self.anatomyMap = mean(self.rawMovie,3);
        end
        
        function calcResponse(self)
            offset = -30;
            % fZeroWindow = [100 200];
            % responseWindow = [500 min(800,size(self.rawMovie,3))];
            fZeroWindow = [1 2];
            responseWindow = [5 10];
            [self.responseMap, self.masterResponseMap, ~] = ...
                dFoverF(self.rawMovie,offset,fZeroWindow,responseWindow,false);
        end
        
        function calcLocalCorrelation(self)
            tilesize = 16;
            self.localCorrMap = computeLocalCorrelation(self.rawMovie,tilesize);
        end
    end
    
    % Methods for ROI-based processing
    methods
        function set.currentRoi(self,roi)
            if isvalid(roi) && isa(roi,'RoiFreehand')
                RoiInArray = NrModel.isInRoiArray(self,roi);
                if RoiInArray
                    if RoiInArray > 1
                        warning('Multiple handles to same ROI!')
                    end
                self.currentRoi = roi;
                self.currentTimeTrace = ...
                    getTimeTrace(self.rawMovie,roi);
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
        % or position of a ROI
            
            if isnumeric(varargin{1}) && ~isempty(varargin{2})
                % TODO imageInfo
                position = varargin{1};
                imageInfo = varargin{2};
                invalidPosition = ~isempty(position) && ~ ...
                    isequal(size(position,2),2);
                if invalidPosition
                    error('Invalid Position')
                end
                roi = RoiFreehand(0,position,imageInfo);
            else if isvalid(varargin{1}) && isa(varargin{1}, ...
                                                'RoiFreehand')
                    % TODO check id conflict
                    roi = varargin{1};
            else
                error('Type error! Input should be ROI position or ROI structure.')
            end
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
        
        function deleteRoi(self)
            delete(self.currentRoi)
            roiArray = self.roiArray;
            self.roiArray = roiArray(cellfun(@isvalid,roiArray));
        end
    end
    
    methods(Static)
        function result = isInRoiArray(self,roi)
            roiArray = self.roiArray;
            existArray = cellfun(@(x) x == roi,roiArray);
            result = sum(existArray);
        end
    end
end
