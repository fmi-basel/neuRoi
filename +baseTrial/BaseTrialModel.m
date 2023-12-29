classdef BaseTrialModel < handle
    properties (SetObservable)
        roiArr
    end
    
    events
        roiAdded
        roiDeleted
        roiUpdated
        roiArrReplaced
        roiTagChanged
        
        roiSelected
        roiUnselected
        roiSelectionCleared
        
        roiNewAlpha
        roiNewAlphaAll
    end

    methods
        % ROI CRUD operations
        function addRoi(self, varargin)
            error('Not implemented.')
        end
        
        function selectSingleRoi(self, tag)
            self.roiArr.selectRois([tag]);
            notify(self, 'roiSelected', NrEvent.RoiEvent(tag));
        end
        
        function unselectAllRois(self)
            self.roiArr.selectRois([]);
            notify(self,'roiSelectionCleared');
        end
        
        function selectLastRoi(self)
            roi = self.roiArr.selectLastRoi();
            notify(self, 'roiSelected', NrEvent.RoiEvent(roi.tag));
        end
        
        function selectRoi(self, tag)
            self.roiArr.selectRoi(tag);
            notify(self, 'roiSelected', NrEvent.RoiEvent(tag));
        end
        
        function unselectRoi(self, tag)
            self.roiArr.unselectRoi(tag);
            % TODO
            notify(self, 'roiUnselected', NrEvent.RoiEvent(tag));
        end
        
        function res = singleRoiSelected(self)
            res = length(self.roiArr.getSelectedIdxs()) == 1;
        end
        
        function selectRoisByOverlay(self, overlay)
            overlayMask = createMask(overlay);
            mask = self.roiArr.convertToMask();
            selectedMask = overlayMask .* mask;
            tags = unique(selectedMask);
            tags(tags == 0) = [];
            self.roiArr.selectRois(tags)
            notify(self, 'roiSelected');
        end
        
        function updateRoi(self, tag, position)
            [newRoi, oldRoi] = self.roiArr.updateRoi(tag, position);
            notify(self,'roiUpdated', NrEvent.RoiUpdatedEvent(newRoi, oldRoi));
        end
        
        function moveRoi(self, tag, offset)
            [newRoi, oldRoi] = self.roiArr.moveRoi(tag, offset);
            notify(self,'roiUpdated', NrEvent.RoiUpdatedEvent(newRoi, oldRoi));
        end

    end
end

