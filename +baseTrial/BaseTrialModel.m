classdef BaseTrialModel < handle
    properties (SetObservable)
        selectedRoiTags
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
    
end

