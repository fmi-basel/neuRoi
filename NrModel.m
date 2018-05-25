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
            nFrame = 200;
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
            fZeroWindow = [100 200];
            responseWindow = [500 min(800,size(self.rawMovie,3))];
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
            self.currentRoi = roi;
            self.currentTimeTrace = ...
                roi.getTimeTrace(self.rawMovie);
        end
        
        function addRoi(self,roi)
            if isempty(self.roiArray)
                roi.id = 1;
            else
                roi.id = self.roiArray{end}.id + 1;
            end
            self.roiArray{end+1} = roi;
            self.currentRoi = roi;
        end
        
        function setCurrentRoiByTag(self,tag)
            if strfind(tag,'roi_')
                roiArray = self.roiArray;
                currentRoiArray = roiArray(cellfun(@(x) strcmp(tag,x.getTag()), ...
                                                   roiArray));
                if length(currentRoiArray) == 1
                    currentRoi = currentRoiArray{:};
                    self.currentRoi = currentRoi;
                else
                    error('Tag did not match or more than one ROI matched')
                end
            else
                error(sprintf('Tag %s is wrong format',tag))
            end
        end
        
        function deleteRoi(self)
            delete(self.currentRoi)
            roiArray = self.roiArray;
            self.roiArray = roiArray(cellfun(@isvalid,roiArray));
        end
    end
end
