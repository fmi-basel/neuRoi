classdef RoiGroup
    properties
        imageSize
        roiArray
        color
        groupName
    end

    methods
        function self = RoiGroup(imageSize,color,groupName)
            self.imageSize = imageSize;
            self.roiArray = RoiFreehand.empty();
            self.color=color;
            self.groupName=groupName;
        end

    end
end

