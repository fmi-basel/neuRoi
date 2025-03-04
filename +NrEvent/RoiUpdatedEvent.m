classdef (ConstructOnLoad) RoiUpdatedEvent < ...
        event.EventData
    % ROIDELETEDEVENT subclass of event.EventData to pass the
    % data in an event of roi deletion
    % Usage: data = RoiDeletedEvent(tagArray)
    properties
        newRoi
        oldRoi
    end
    
    methods
        function self = RoiUpdatedEvent(newRoi, oldRoi)
            self.newRoi = newRoi;
            self.oldRoi = oldRoi;
        end
    end
end
