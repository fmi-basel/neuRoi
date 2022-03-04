classdef RoiM
    properties
        tag
        position
    end
    
    methods
        function self = RoiM(position,varargin)
            pa = inputParser;
            addRequired(pa,'position',@ismatrix);
            addParameter(pa,'tag','',@isnumeric);
            parse(pa,position,varargin{:})
            pr = pa.Results;
                
            if isempty(pr.position) || ~isequal(size(pr.position,2),2)
                error('Invalid Position!')
            end
            % TODO position must be integers
            self.position = pr.position;
            self.tag = pr.tag;
        end
        
        function mask = createMask(self,imageSize)
            mask = zeros(imageSize);
            pos = self.position;
            linearInd = sub2ind(imageSize, pos(:,2),pos(:,1));
            try
                mask(linearInd) = 1;
            catch
                disp('create mask error')
            end
            
        end

        function [mask,offset] = createSmallMask(self,extend)
            offset = min(self.position,[],1) - 1 - extend;
            roiSize = ceil(max(self.position,[],1) - offset) + extend;
            mask = zeros(roiSize(end:-1:1));
            posShifted = self.position - offset;
            linearInd = sub2ind(roiSize(end:-1:1), posShifted(:,2),posShifted(:,1));
            mask(linearInd) = 1;
        end
    end
end
