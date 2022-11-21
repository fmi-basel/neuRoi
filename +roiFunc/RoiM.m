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

            disp(pr.freeHand)
            disp(isempty(pr.freeHand))
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
        
        function centroid = getCentroid(self)
            error('Not implemented')
        end
        
    end
    
    methods(Static)
        function valid = verifyPosition(position)
            valid = isequal(size(position,2),2) & all(position>=0, 'all');
        end
        
        function position = convertFreeHandPos(freeHand)
            polyPos = freeHand.Position;
            [xlim, ylim] = boundingbox(polyshape(polyPos(:,1), polyPos(:,2)));
            offset = [xlim(1), ylim(1)];
            maskSize = [xlim(2)-xlim(1), ylim(2)-ylim(1)];
            mask = freeHand.createMask(maskSize(1), maskSize(2));
            mpos = find(mask==1);
            position = mpos + offset;
        end
    end
end
