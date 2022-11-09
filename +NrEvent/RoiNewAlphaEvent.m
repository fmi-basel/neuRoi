classdef (ConstructOnLoad) RoiNewAlphaEvent < ...
        event.EventData
    % ROINEWALPHAEVENT subclass of event.EventData to pass the
    % data in an event of roi deletion
    % Usage: data = RoiDeletedEvent(tagArray)
    properties
        roiArray
        AllRois=false
        NewAlpha=0.5
    end
    
    methods
        function self = RoiNewAlphaEvent(varargin)
            if nargin == 1
            self.roiArray = varargin{1};
            elseif nargin == 3
                self.roiArray = varargin{1};
                self.AllRois = varargin{2};
                self.NewAlpha = varargin{3};
            else
                error('Wrong usage!')
            end
        end
    end
end
