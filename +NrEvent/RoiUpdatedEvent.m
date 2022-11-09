classdef (ConstructOnLoad) RoiUpdatedEvent < ...
        event.EventData
    % ROIDELETEDEVENT subclass of event.EventData to pass the
    % data in an event of roi deletion
    % Usage: data = RoiDeletedEvent(tagArray)
    properties
        roiArray
    end
    
    methods
        function self = RoiUpdatedEvent(roiArray)
            self.roiArray = roiArray;
        end
    end
end
