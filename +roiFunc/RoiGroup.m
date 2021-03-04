classdef RoiGroup
    properties
        imageSize
        roiArray
    end

    methods
        function self = RoiGroup(imageSize)
            self.imageSize = imageSize;
            self.roiArray = RoiFreehand.empty();
        end

    end
end

