classdef Transformation
    properties
        type
        flowField
    end
    
    methods
        function self = Transformation(type, varargin)
            pa = inputParser;
            addParameter(pa, 'type', 'identity', @ischar) % 'bunwarpj' for bUnwarpJ transformation, 'opticFlow' for optical flow transformation
            addParameter(pa, 'flowField', [], @isnumeric) % flow field for optical flow transformation
            parse(pa, type, varargin{:})
            pr = pa.Results;

            self.type = pr.type;
            self.flowField = pr.flowField;
        end
        
    end
end
