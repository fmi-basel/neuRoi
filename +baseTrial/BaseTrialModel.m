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
        
        function selectLastRoi(self)
            self.roiArr.selectLastRoi();
            notify(self,'roiSelected');
        end
        
        function selectRoisByIdxs(self, idxs)
            self.roiArr.selectRoisByIdxs(idxs);
            notify(self,'roiSelected');
        end
        
        function updateRoiByIdx(self, idx, position)
            [newRoi, oldRoi] = self.roiArr.updateRoiByIdx(idx, position);
            notify(self,'roiUpdated', NrEvent.RoiUpdatedEvent(newRoi, oldRoi));
        end
        
        
        % function selectSingleRoi(self,varargin)
        %     if nargin == 2
        %         if strcmp(varargin{1},'last')
        %             ind = length(self.roiArray);
        %             tag = self.roiArray(ind).tag;
        %         else
        %             tag = varargin{1};
        %             ind = self.findRoiByTag(tag);
        %         end
        %     else
        %         error('Too Many/few input args!')
        %     end
            
        %     if ~isequal(self.selectedRoiTagArray,[tag])
        %         self.unselectAllRoi();
        %         self.selectRoi(tag);
        %     end
        % end
        
        % function selectRoi(self,tag)
        %     if ~ismember(tag,self.selectedRoiTagArray)
        %         ind = self.findRoiByTag(tag);
        %         self.selectedRoiTagArray(end+1)  = tag;
        %         notify(self,'roiSelected',NrEvent.RoiEvent(tag));
        %         disp(sprintf('ROI #%d selected',tag))
        %     end
        % end
        
        % function unselectRoi(self,tag)
        %     tagArray = self.selectedRoiTagArray;
        %     tagInd = find(tagArray == tag);
        %     if tagInd
        %         self.selectedRoiTagArray(tagInd) = [];
        %         notify(self,'roiUnSelected',NrEvent.RoiEvent(tag));
        %     end
        % end

    end
end

