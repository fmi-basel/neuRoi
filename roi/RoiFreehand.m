classdef RoiFreehand < matlab.mixin.Copyable
    properties
        id
        position
        imageInfo
    end
    
    methods
        function self = RoiFreehand(id,position,imageInfo)
            self.id = id;
            self.position = position;
            self.imageInfo = imageInfo;
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
