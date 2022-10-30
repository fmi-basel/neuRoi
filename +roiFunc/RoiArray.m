classdef RoiArray < handle
    properties
        imageSize
        meta
    end
    
    properties (Access = private)
        roiList
        tagList
        selectedRois
        selectedTags
    end
    
    methods
        function self = RoiArray(varargin)
            pa = inputParser;
            addParameter(pa,'maskImg',[],@ismatrix);
            addParameter(pa,'maskImgFile','',@(x) isstring(x)||ischar(x));
            addParameter(pa,'imageSize',@ismatrix);
            addParameter(pa,'roiList',[]);
            parse(pa,varargin{:})
            pr = pa.Results;
            self.roiList = roiFunc.RoiM.empty();
            self.tagList = [];
            
            if length(pr.maskImg)
                self.importFromMaskImg(pr.maskImg);
                self.imageSize = size(pr.maskImg);
            elseif length(pr.maskImgFile)
                maskImg = imread(pr.maskImgFile);
                self.importFromMaskImg(maskImg);
                self.imageSize = size(maskImg);
            else
                self.imageSize = pr.imageSize;
                self.roiList = pr.roiList;
                self.tagList = arrayfun(@(x) x.tag, self.roiList);
            end
        end
        
        function tagList = getTagList(self)
            tagList = self.tagList;
        end

        function roiList = getRoiList(self)
            roiList = self.roiList;
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
        
        function addRoi(self, roi)
            tag = roi.tag;
            if ismember(tag, self.tagList)
                error(sprintf('ROI #%d already in ROI array!', tag))
            end
            self.roiList(end+1) = roi;
            self.tagList(end+1) = tag;
        end
        
        function addRois(self, rois)
            for k=1:length(rois)
                self.addRoi(rois(k))
            end
        end
        
        function updateRoi(self, tag, roi)
            idx = self.findRoi(tag);
            if idx
                self.roiList(idx) = roi;
            else
                error(sprintf('ROI #%d not found!', tag))
            end
        end
        
        function deleteRoi(self, tag)
            idx = self.findRoi(tag);
            self.roiList(idx) = [];
            self.tagList(idx) = [];
        end
        
        function deleteRois(self, tags)
            for k=1:length(tags)
                self.deleteRoi(tags(k));
            end
        end
        
        function selectRois(self, tags)
            self.selectedRois = roiFunc.RoiM.empty();
            idxs = arrayfun(@(x) self.findRoi(x), tags);
            self.selectedRois = self.roiList(idxs);
            self.selectedTags = tags;
        end
        
        function rois = getSelectedRois(self)
            rois = self.selectedRois;
        end
        
        function idx = findRoi(self, tag)
            idx = find(self.tagList == tag);
            if ~length(idx)
                error(sprintf('ROI #%d not found!', tag))
            elseif length(idx) > 1
                error(sprintf('Multiple ROIs found for #%d!', tag))
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

