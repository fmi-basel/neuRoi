classdef RoiArray < handle
    properties
        imageSize
        name
        meta
        
        DEFAULT_GROUP = 'default'
    end
    
    properties (Access = private)
        roiList
        tagList
        roiGroupTagList
        selectedIdxs
        selectedRois
        
        groupNames
        groupTags
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
            self.addGroup(self.DEFAULT_GROUP);
            
            self.roiList = roiFunc.RoiM.empty();
            self.tagList = [];
            
            if length(pr.maskImg)
                self.importFromMaskImg(pr.maskImg, self.DEFAULT_GROUP);
                self.imageSize = size(pr.maskImg);
            elseif length(pr.maskImgFile)
                maskImg = imread(pr.maskImgFile);
                self.importFromMaskImg(maskImg, self.DEFAULT_GROUP);
                self.imageSize = size(maskImg);
            else
                self.imageSize = pr.imageSize;
                self.addRois(pr.roiList, self.DEFAULT_GROUP);
            end
        end
        
        function tagList = getTagList(self)
            tagList = self.tagList;
        end

        function roiList = getRoiList(self)
            roiList = self.roiList;
        end

        function idx = findRoi(tag)
            idx = find(self.tagList == tag);
            if ~length(idx)
                error(sprintf('roi #%s not found!', tag))
            end
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
        
        function addRoi(self, roi, groupName)
            tag = roi.tag;
            if ismember(tag, self.tagList)
                error(sprintf('ROI #%d already in ROI array!', tag))
            end
            
            groupTag = self.findGroupTag(groupName);
            self.roiGroupTagList(end+1) = groupTag;
            roi.setMeta('groupName', groupName)
            
            self.roiList(end+1) = roi;
            self.tagList(end+1) = tag;
        end
        
        function addRois(self, rois, groupName)
            for k=1:length(rois)
                self.addRoi(rois(k), groupName)
            end
        end
        
        function updateRoi(self, tag, roi)
            idx = self.findRoi(tag);
            if idx
                % only update ROI position
                self.roiList(idx).position = roi.position;
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
            self.selectedIdxs = idxs;
            self.selectedRois = self.roiList(idxs);
        end
        
        function rois = getSelectedRois(self)
            rois = self.selectedRois;
        end
        
        function rois = getSelectedRoisFromGroup(self, groupName)
            gidxs = self.findRoisInGroup(groupName);
            idxs = intersect(self.selectedIdxs, gidxs);
            rois = self.roiList(idxs);
        end
        
        function idxs = findRoisInGroup(groupName)
            groupTag = self.findGroupTag(groupName);
            idxs = find(self.roiGroupTagList == groupTag);
        end
    


        function idx = findGroupIdx(self, groupName)
            idx = find(strcmp(self.groupNames, groupName));
            if ~length(idx)
                error(sprintf('Group %s not found!', groupName))
            end
        end
        
        function groupTag = findGroupTag(self, groupName)
            groupTag = self.groupTags(self.findGroupIdx(groupName));
        end
    
        function addGroup(self, groupName)
            self.groupNames{end+1} = groupName;
            newTag = max([self.groupTags, 0]) + 1;
            self.groupTags = [self.groupTags, newTag];
        end
        
        function moveRoisToGroup(self, tags, groupName)
            groupTag = self.findGroupTag(groupName);
            for k=1:length(tags)
                idx = self.findRoi(tags(k));
                self.roiGroupTagList(idx) = groupTag;
                self.roiList(idx).setMeta('groupName', groupName);
            end
        end
        
        function importFromMaskImg(self, maskImg, groupName)
            self.imageSize = size(maskImg);
            tagArray = unique(maskImg);
            tagArray(tagArray==0) = [];
            for k=1:length(tagArray)
                tag = tagArray(k);
                mask = maskImg == tag;
                [mposY,mposX] = find(mask);
                position = [mposX,mposY];
                roi = roiFunc.RoiM(position,'tag',double(tag));
                self.addRoi(roi, groupName);
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

