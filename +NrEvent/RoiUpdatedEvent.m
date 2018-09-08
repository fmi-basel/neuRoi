classdef (ConstructOnLoad) RoiUpdatedEvent < ...
        event.EventData
    % ROIDELETEDEVENT subclass of event.EventData to pass the
    % data in an event of roi deletion
    % Usage: data = RoiDeletedEvent(tagArray)
    properties
        roi
    end
    
    methods
        function self = RoiUpdatedEvent(roi)
            self.roi = roi;
        end
    end
end
