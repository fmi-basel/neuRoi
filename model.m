classdef model < handle
    properties (SetObservable)
        filePath
        meta
        rawMovie
        anatomyMap
        responseMap
        masterResponseMap
        localCorrMap
        displayState
        stateArray
    end
    
    methods
        function self = model(filePath)
            self.filePath = filePath;
            self.loadMovie(filePath);
            self.preprocessMovie();
            self.calcAnatomy();
            self.calcResponse;
            self.localCorrMap = zeros(size(self.rawMovie(:,:,1)));
            self.stateArray = {'anatomy','response', ...
                               'masterResponse','localCorr'};
            self.displayState = self.stateArray{1};
        end
        
        function loadMovie(self,filePath)
            meta = readMeta(filePath);
            
            nPlane = 1;
            meta.framerate = meta.framerate/nPlane;
            self.meta = meta
            
            startFrame = 50;
            nFrame = 700;
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
end
