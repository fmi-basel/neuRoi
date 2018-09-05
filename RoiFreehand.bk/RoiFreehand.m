classdef RoiFreehand < matlab.mixin.Copyable
    properties
        id
        position
        imageInfo
    end
    
    methods
        function self = RoiFreehand(varargin)
            if nargin == 1
                roiStruct = varargin{1};
                self.id = roiStruct.id;
                self.position = roiStruct.position;
                self.imageInfo = roiStruct.imageInfo;
            elseif nargin == 3
                self.id = varargin{1};
                self.position = varargin{2};
                self.imageInfo = varargin{3};
            else
                error('Wrong number of input arguments!')
            end
        end
        
        function mask = createMask(self)
            [roix,roiy] = getPixelPosition(self.position, ...
                                           self.imageInfo);
            imageSize = self.imageInfo.imageSize;
            mask = poly2mask(roix,roiy,imageSize(1),imageSize(2));
        end
    end
end

function [roix,roiy] = getPixelPosition(position,imageInfo)
    xdata = imageInfo.xdata;
    ydata = imageInfo.ydata;
    imageSize = imageInfo.imageSize;
    
    vert = position;
    xi = vert(:,1);
    yi = vert(:,2);
    
    % Transform xi,yi into pixel coordinates.
    roix = axes2pix(imageSize(2), xdata, xi);
    roiy = axes2pix(imageSize(1), ydata, yi);
end
