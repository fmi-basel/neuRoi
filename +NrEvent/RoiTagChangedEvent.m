classdef (ConstructOnLoad) RoiTagChangedEvent < ...
        event.EventData
    % ROITAGCHANGEDEVENT subclass of event.EventData to pass the
    % data in an event of roi tag update
    % Usage: data = RoiTagChangedEvent(oldTag,newTag)
    properties
        oldTag
        newTag
    end
    
    methods
        function self = RoiUpdatedEvent(oldTag,newTag)
        self.oldTag = oldTag;
        self.newTag = newTag;
        end
    end
end
