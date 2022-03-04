classdef RoiArray < handle
    properties
        imageSize
        roiList
        meta
    end

    methods
        function self = RoiArray(varargin)
            pa = inputParser;
            addParameter(pa,'imageSize',@ismatrix);
            addParameter(pa,'maskImg',[],@ismatrix);
            addParameter(pa,'maskImgFile','',@(x) isstring(x)||ischar(x));
            addParameter(pa,'roiList',[]);
            parse(pa,varargin{:})
            pr = pa.Results;
            self.roiList = roiFunc.RoiM.empty();
            
            if length(pr.maskImg)
                self.importFromMaskImg(pr.maskImg);
            elseif length(pr.maskImgFile)
                maskImg = imread(pr.maskImgFile);
                self.importFromMaskImg(maskImg);
            elseif length(pr.roiList)
                self.imageSize = pr.imageSize;
                self.roiList = pr.roiList;
            end
        end
        
        function importFromMaskImg(self,maskImg)
            self.imageSize = size(maskImg);
            tagArray = unique(maskImg);
            tagArray(tagArray==0) = [];
            for k=1:length(tagArray)
                tag = tagArray(k);
                mask = maskImg == tag;
                [mposY,mposX] = find(mask);
                position = [mposX,mposY];
                roi = roiFunc.RoiM(position,'tag',double(tag));
                self.roiList(end+1) = roi;
            end
        end

        % function transformRois(tform)
        %     for k=1:length(self.roiList)
        %         roi = self.roiList(k);
        %         roi.transformPosition(tform)
        %     end
        % end
    
        function maskImg = convertToMask(self)
            maskImg = zeros(self.imageSize);
            for roi=self.roiList
                maskImg = min(maskImg + roi.createMask(self.imageSize)*roi.tag, roi.tag);
            end
        end
    end
end

