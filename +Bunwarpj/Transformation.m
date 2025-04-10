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
            addParameter(pa, 'type', 'identity', @ischar) % 'bunwarpj' for bUnwarpJ transformation, 'opticFlow' for optical flow transformation
            addParameter(pa, 'xcorr', [], @isnumeric)
            addParameter(pa, 'ycorr', [], @isnumeric)
            addParameter(pa, 'imageSize', [], @isnumeric)
            parse(pa, type, varargin{:})
            pr = pa.Results;

            self.type = pr.type;
            self.xcorr = pr.xcorr;
            self.ycorr = pr.ycorr;
            self.imageSize = pr.imageSize;
        end
        
    end
end
% transform = Bunwarpj.Transformation('type', 'bunwarpj',...
%                                     'xcorr', xcorr,...
%                                     'ycorr', ycorr,...
%                                     'imageSize', [height, width]);
