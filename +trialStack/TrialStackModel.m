classdef TrialStackModel < handle
    properties
        rawFileList
        anatomyArray
        responseArray
        mapSize
    end
    
    properties (SetObservable)
        currentTrialIdx
        mapType
    end
    
    methods
        function self = TrialStackModel(rawFileList, anatomyArray,...
                                        responseArray)
            % TODO check sizes of all arrays
            self.rawFileList = rawFileList;
            self.anatomyArray = anatomyArray;
            self.responseArray = responseArray;
            self.mapSize = size(anatomyArray(:,:,1));
            self.mapType = 'anatomy';
            self.currentTrialIdx = 1;
        end
        
        function map = getCurrentMap(self)
            switch self.mapType
              case 'anatomy'
                mapArray = self.anatomyArray;
              case 'response'
                mapArray = self.responseArray;
            end
            map.data = mapArray(:,:,self.currentTrialIdx);
            map.type = self.mapType;
            map.meta.trialIdx = self.currentTrialIdx;
            map.meta.fileName = self.rawFileList{self.currentTrialIdx};
        end
        
        function set.currentTrialIdx(self,idx)
            newIdx = min(max(idx,1),length(self.rawFileList));
            self.currentTrialIdx = newIdx;
        end
        
    end

end

