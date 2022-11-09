classdef (ConstructOnLoad) RoiEvent < ...
        event.EventData
    % ROIEVENT subclass of event.EventData to pass the
    % data in an event related to an roi
    % Usage: data = RoiDeletedEvent(tag)
    properties
        tag
    end
    
    methods
        function self = RoiEvent(tag)
            self.tag = tag;
        end
    end
end
