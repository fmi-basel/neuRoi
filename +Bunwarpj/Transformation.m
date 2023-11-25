classdef Transformation
    properties
        type
        xcorr
        ycorr
        imageSize
    end
    
    methods
        function self = Transformation(type, varargin)
            pa = inputParser;
            addParameter(pa, 'type', 'identity', @ischar) % 'bunwarpj' for bUnwarpJ transformation
            addParameter(pa, 'xcorr', [], @ismatrix)
            addParameter(pa, 'ycorr', [], @ismatrix)
            addParameter(pa, 'imageSize', [], @ismatrix)
            
            parse(pa, type, varargin{:})
            pr = pa.Results;

            self.type = pr.type;
            self.xcorr = pr.xcorr;
            self.ycorr = pr.ycorr;
            self.imageSize = pr.imageSize;
        end
        
    end
end
