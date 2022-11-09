classdef Transformation
    properties
        type
        xcorr
        ycorr
        imageSize
    end
    
    methods
        function self = Transformation(varargin)
            pa = inputParser;
            addOptional(pa, 'type', 'identity', @ischar)
            addOptional(pa, 'xcorr', [], @ismatrix)
            addOptional(pa, 'ycorr', [], @ismatrix)
            addOptional(pa, 'imageSize', [], @ismatrix)
            
            parse(pa, varargin{:})
            pr = pa.Results;

            self.type = pr.type;
            self.xcorr = pr.xcorr;
            self.ycorr = pr.ycorr;
            self.imageSize = pr.imageSize;
        end
        
    end
    
    
    
end
