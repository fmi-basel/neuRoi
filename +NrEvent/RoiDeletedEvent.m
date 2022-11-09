classdef (ConstructOnLoad) RoiDeletedEvent < ...
        event.EventData
    % ROIDELETEDEVENT subclass of event.EventData to pass the
    % data in an event of roi deletion
    % Usage: data = RoiDeletedEvent(tagArray)
    properties
        tagArray
    end
    
    methods
        function self = RoiDeletedEvent(tagArray)
            self.tagArray = tagArray;
        end
    end
end
