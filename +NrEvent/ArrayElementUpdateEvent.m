classdef (ConstructOnLoad) ArrayElementUpdateEvent < ...
        event.EventData
% ARRAYELEMENTUPDATEEVENT subclass of event.EventData to pass the
% data in an event of array element update
% Usage: data = ArrayElementUpdateEvent(ind,[newValue])
    properties
        ind
        newValue
    end
    
    methods
        function self = ArrayElementUpdateEvent(varargin)
            if nargin == 1
                self.ind = varargin{1};
            elseif nargin == 2
                self.ind = varargin{1};
                self.newValue = varargin{2};
            else
                error('Wrong usage!')
                help ArrayElementUpdateEvent
            end
        end
    end
end
 
