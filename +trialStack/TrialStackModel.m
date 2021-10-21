classdef TrialStackModel < handle
    properties
        rawFileList
        anatomyArray
        responseArray
        mapSize
        nTrial
        
        contrastLimArray
        contrastForAllTrial
        mapTypeList
		roiProvided
        roiArrays
        SingleRoi
    end
    
    properties (SetObservable)
        currentTrialIdx
        mapType
    end
    
    methods
        function self = TrialStackModel(rawFileList, anatomyArray,...
                                        responseArray,roiArrays)
            % TODO check sizes of all arrays
            self.rawFileList = rawFileList;
            self.anatomyArray = anatomyArray;
            self.responseArray = responseArray;
            self.mapSize = size(anatomyArray(:,:,1));
            self.mapType = 'anatomy';
            self.nTrial = length(rawFileList)
            self.currentTrialIdx = 1;
            self.mapTypeList = {'anatomy','response'};
            self.contrastLimArray = cell(length(self.mapTypeList),...
                                         self.nTrial);
            self.contrastForAllTrial = false
			if ~exist('roiArrays','var')
                self.roiProvided= false;
            else
                self.roiArrays=roiArrays;
                self.roiProvided=true;
                roiSize=size(roiArrays);
                if roiSize(1)==1
                    self.SingleRoi=true;
                else
                    self.SingleRoi=false
                    if roiSize(1)~=self.mapSize
                        self.roiArrays= [];
                        self.roiProvided=false;
                    end
                end

            end
        end
        
        function data = getMapData(self,mapType,trialIdx)
            switch mapType
              case 'anatomy'
                mapArray = self.anatomyArray;
              case 'response'
                mapArray = self.responseArray;
            end
            data = mapArray(:,:,trialIdx);
        end
        
        function map = getCurrentMap(self)
            map.data = self.getMapData(self.mapType,self.currentTrialIdx);
            map.type = self.mapType;
            map.meta.trialIdx = self.currentTrialIdx;
            
            map.meta.fileName = self.rawFileList{self.currentTrialIdx};
            contrastLim = self.getContrastLimForCurrentMap();
            if isempty(contrastLim)
                contrastLim = helper.minMax(map.data);
                self.saveContrastLim(contrastLim);
            end
            map.contrastLim = contrastLim;
        end
        
        function saveContrastLim(self,contrastLim)
            mapTypeIdx = self.findMapTypeIdx(self.mapType);
            if self.contrastForAllTrial
                [self.contrastLimArray{mapTypeIdx,:}] = deal(contrastLim);
            else
                self.contrastLimArray{mapTypeIdx,self.currentTrialIdx} = contrastLim;
            end
        end
        
        function climit = getContrastLimForCurrentMap(self)
            mapTypeIdx = self.findMapTypeIdx(self.mapType);
            climit = self.contrastLimArray{mapTypeIdx,self.currentTrialIdx};
        end
        
        function MaxTrialnumber = getMaxTrialnumber(self)
            MaxTrialnumber = length(self.anatomyArray(1,1,:));
        end

        
        function idx = findMapTypeIdx(self, mapType)
            idx = find(strcmp(self.mapTypeList, self.mapType));
        end
        
        function set.currentTrialIdx(self,idx)
            newIdx = min(max(idx,1),length(self.rawFileList));
            self.currentTrialIdx = newIdx;
        end
        
        function selectMapType(self,idx)
           self.mapType = self.mapTypeList{idx};
        end
		function roiArray = getCurrentRoiArray(self)
            if self.roiProvided== true
                if self.SingleRoi
                      roiArray =self.roiArrays;
                else
                    roiArray =self.roiArrays(self.currentTrialIdx,:);
                end
            else
                roiArray=[];
            end
        end
    end

end

