classdef (ConstructOnLoad) RoiDeletedEvent < ...
        event.EventData
    % ROIDELETEDEVENT subclass of event.EventData to pass the
    % data in an event of roi deletion
    % Usage: data = RoiDeletedEvent(tagArray)
    properties
        rois
    end
    
    methods
        function self = RoiDeletedEvent(rois)
            self.rois = rois;
        end
    end
end
