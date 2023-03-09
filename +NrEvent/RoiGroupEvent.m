classdef (ConstructOnLoad) RoiGroupEvent < ...
        event.EventData
    % ROIEVENT subclass of event.EventData to pass the
    % data in an event related to an roi
    % Usage: data = RoiDeletedEvent(tag)
    properties
        groupIdx
        groupName
        color
    end
    
    methods
        function self = RoiGroupEvent(groupIdx,groupName,color)
            self.groupIdx=groupIdx;
            self.groupName = groupName;
            self.color = color;
        end
    end
end