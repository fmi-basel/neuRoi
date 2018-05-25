% EXTFREEHANDROI extended class for drawing free-hand ROI on
% calcium imaging movie
% Usage: h = ExtFreehandRoi

classdef ExtFreehandRoi < imfreehand
    properties
        id
    end
    
    methods
        function set.id(self,id)
            if isnumeric(id) && id > 0
                self.id = uint8(id);
                set(self,'Tag',sprintf('roi_%04d',id))
            else
                error('ID should be a positive integer!')
            end
        end
        
        function tag = getTag(self)
            tag = get(self,'Tag')
        end
        
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

    methods (Static)
        function id = getIdByTag(tag)
            id = sscanf(tag,'roi_%d')
        end
    end
end
