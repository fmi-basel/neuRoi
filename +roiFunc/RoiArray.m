classdef RoiArray < handle
    properties
        imageSize
        meta
    end
    
    properties (Access = private)
        roiList
        tagList
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
            self.tagList = [];
            
            if length(pr.maskImg)
                self.importFromMaskImg(pr.maskImg);
            elseif length(pr.maskImgFile)
                maskImg = imread(pr.maskImgFile);
                self.importFromMaskImg(maskImg);
            elseif length(pr.roiList)
                self.imageSize = pr.imageSize;
                self.roiList = pr.roiList;
                self.tagList = arrayfun(@(x) x.tag, roiList)
            end
        end
        
        function addRoi(self, roi)
            self.roiList(end+1) = roi;
            self.tagList(end+1) = roi.tag;
        end
        
        function tagList = getTagList(self)
            tagList = self.tagList;
        end
        
        function rois = getRoisByTags(self, tags)
            [~, idxs] = ismember(tags, self.tagList);
            rois = roiFunc.RoiM.empty();
            for k = 1:length(tags)
                idx = idxs(k);
                if idx
                    rois(k) = self.roiList(idx);
                end
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
                self.addRoi(roi);
            end
        end
    
        function maskImg = convertToMask(self)
            maskImg = zeros(self.imageSize);
            for roi=self.roiList
                maskImg = min(maskImg + roi.createMask(self.imageSize)*roi.tag, roi.tag);
            end
        end
    end
end

