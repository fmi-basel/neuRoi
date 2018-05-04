% EXTFREEHANDROI extended class for drawing free-hand ROI on
% calcium imaging movie
% Usage: h = ExtFreehandRoi

classdef ExtFreehandRoi < imfreehand
    properties
        id
    end
    
    methods
        function timeTrace = getTimeTrace(self,rawMovie)
            mask = createMask(self);
            [maskIndX maskIndY] = find(mask==1);
            roiMovie = rawMovie(maskIndX,maskIndY,:);
            timeTrace = mean(mean(roiMovie,1),2);
            timeTrace =timeTrace(:);
        end
    end
   
end
