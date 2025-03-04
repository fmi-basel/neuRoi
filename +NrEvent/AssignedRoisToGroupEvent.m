classdef (ConstructOnLoad) AssignedRoisToGroupEvent < event.EventData
    properties
        rois
    end
    
    methods
        function self = AssignedRoisToGroupEvent(rois)
            self.rois = rois;
        end
    end
end
