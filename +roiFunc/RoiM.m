classdef RoiM
    properties
        tag
        position
        meta
    end
    
    methods
        function self = RoiM(position,varargin)
            pa = inputParser;
            addParameter(pa, 'position', [], @ismatrix);
            addParameter(pa, 'freeHand', [], @ismatrix);
            addParameter(pa, 'tag', '', @isnumeric);
            parse(pa, position, varargin{:})
            pr = pa.Results;

            if ~isempty(pr.position)
                position = pr.position;
            elseif ~isempty(pr.freeHand)
                position = roiFunc.RoiM.convertFreeHandPos(pr.freeHand);
            else
                error('Either a mask position or a FreeHand ROI needs to be supplied!')
            end
            
            if ~roiFunc.RoiM.verifyPosition(position)
                error('Invalid Position!')
            end
            
            self.position = position;
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
        
        function centroid = getCentroid(self)
            centroid = mean(self.position, 1);
        end
        
        function img = addMaskToImg(self, img, value)
            if ~exist('value', 'var')
                if isempty(self.tag)
                    error('ROI tag not set!')
                end
                value = self.tag;
            end
            
            imageSize = size(img);
            pos = self.position;
            linearInd = sub2ind(imageSize, pos(:,2), pos(:,1));
            img(linearInd) = value;
        end

        function position = getMovedPos(self, offset)
            position = self.position + round(offset);
        end
        
    end
    
    methods(Static)
        function valid = verifyPosition(position)
            valid = isequal(size(position,2),2) & all(position>=0, 'all');
        end
        
        function position = convertFreeHandPos(freeHand)
            mask = freeHand.createMask();
            [row,col] = find(mask==1);
            position = [row,col];
        end
    end
end
