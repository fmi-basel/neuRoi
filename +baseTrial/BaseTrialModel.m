classdef BaseTrialModel < handle
    properties (SetObservable)
        roiArr
    end
    
    events
        roiAdded
        roiDeleted
        roiUpdated
        roiArrayReplaced
        roiTagChanged
        
        roiSelected
        roiUnSelected
        roiSelectionCleared
        
        roiNewAlpha
        roiNewAlphaAll
    end

    methods
        function addRoi(self, varargin)
            error('Not implemented.')
        end
        
        function selectRois(self, tagLists)
            self.roiArr.selectRois(tagLists);
            notify(self,'roiSelected');
        end
        
        function unselectAllRois(self)
            self.roiArr.selectRois([]);
            notify(self,'roiSelected');
        end

        
        function selectLastRoi(self)
            self.roiArr.selectLastRoi();
            notify(self,'roiSelected');
        end
        
        function selectRoi(self, tag)
            self.roiArr.selectRoi(tag);
            notify(self,'roiSelected');
        end
        
        function unselectRoi(self, tag)
            self.roiArr.unselectRoi();
            notify(self,'roiSelected');
        end
        
        function selectRoisByIdxs(self, idxs)
            self.roiArr.selectRoisByIdxs(idxs);
            notify(self,'roiSelected');
        end
        
        function res = singleRoiSelected(self)
            res = length(self.roiArr.getSelectedIdxs()) == 1;
        end
        
        function updateRoiByIdx(self, idx, position)
            [newRoi, oldRoi] = self.roiArr.updateRoiByIdx(idx, position);
            notify(self,'roiUpdated', NrEvent.RoiUpdatedEvent(newRoi, oldRoi));
        end
        
        function moveRoi(self, tag, offset)
            [newRoi, oldRoi] = self.roiArr.moveRoi(tag, offset);
            notify(self,'roiUpdated', NrEvent.RoiUpdatedEvent(newRoi, oldRoi));
        end

    end
end

