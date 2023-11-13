classdef (ConstructOnLoad) AssignedRoiToGroupEvent < event.EventData
    properties
        roi
    end
    
    methods
        function self = AssignedRoiToGroupEvent(roi)
            self.roi = roi;
        end
    end
end
