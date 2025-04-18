classdef RoiArray < handle
    properties
        imageSize
        DEFAULT_GROUP = 'default'
        currentGroupName
    end
    
    properties (SetObservable)
        groupNames
    end
    
    properties (SetAccess = private)
        roiList
        tagList
        roiGroupTagList
        selectedIdxs
        
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
            
            self.currentGroupName = self.groupNames(end);
        end
        
        function tagList = getTagList(self)
            tagList = self.tagList;
        end

        function setTagList(self, tagList)
            % Update tag of each ROI
            for k=1:length(self.roiList)
                tag = tagList(k);
                self.roiList(k).tag = tag;
            end
            % Update tagList
            self.tagList = tagList;
        end

        function roiList = getRoiList(self)
            roiList = self.roiList;
        end

        function idx = findRoi(self, tag)
            idx = find(self.tagList == tag);
            if ~length(idx)
                error(sprintf('ROI #%d not found!', tag))
            end
        end

        function idxs = findRoisByTags(self, tags)
            [~, idxs] = ismember(tags, self.tagList);
        end


        function roi = getRoi(self, tag)
            idx = self.findRoi(tag);
            roi = self.roiList(idx);
        end
        
        function roi = getLastRoi(self)
            roi = self.roiList(end);
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
                error('ROI #%d already in ROI array!', tag)
            end
            
            groupTag = self.findGroupTag(groupName);
            self.roiGroupTagList(end+1) = groupTag;
            roi.meta.groupName = groupName;
            roi.meta.groupTag = groupTag;
            
            self.roiList(end+1) = roi;
            self.tagList(end+1) = tag;
        end
        
        function addRois(self, rois, groupName)
            for k=1:length(rois)
                self.addRoi(rois(k), groupName)
            end
        end
        
        function [newRoi, oldRoi] = updateRoi(self, tag, roi)
            idx = self.findRoi(tag);
            [newRoi, oldRoi] = self.updateRoiByIdx(idx, roi);
        end
        
        function [newRoi, oldRoi] = moveRoi(self, tag, offset)
            idx = self.findRoi(tag);
            % TODO move ROI limit in x and y
            oldRoi = self.roiList(idx);
            self.roiList(idx).position = oldRoi.getMovedPos(offset);
            newRoi = self.roiList(idx);
        end
        
        function [newRoi, oldRoi] = updateRoiByIdx(self, idx, roi)
        % UPDATEROIBYIDX only update ROI position
            oldRoi = self.roiList(idx);
            self.roiList(idx).position = roi.position;
            newRoi = self.roiList(idx);
        end
        
        function roi = deleteRoi(self, tag)
            self.unselectRoi(tag);
            idx = self.findRoi(tag);
            roi = self.roiList(idx);
            self.roiList(idx) = [];
            self.tagList(idx) = [];
            self.roiGroupTagList(idx) = [];
        end
        
        function deleteRois(self, tags)
            for k=1:length(tags)
                self.deleteRoi(tags(k));
            end
        end

        function rois = deleteSelectedRois(self)
            tags = self.getSelectedTags();
            rois = roiFunc.RoiM.empty();
            for k=1:length(tags)
                tag = tags(k);
                rois(k) = self.deleteRoi(tag);
            end
            % Clear selection
            self.selectedIdxs = [];
        end

        function selectRoisByIdxs(self, idxs)
            self.selectedIdxs = idxs;
        end
        
        function selectRois(self, tags)
            idxs = arrayfun(@(x) self.findRoi(x), tags);
            self.selectRoisByIdxs(idxs);
        end

        function roi = selectLastRoi(self)
            idxs = [length(self.roiList)];
            self.selectRoisByIdxs(idxs);
            roi = self.roiList(end);
        end
        
        function selectAllRois(self)
            self.selectedIdxs = 1:length(self.roiList);
        end
        
        function selectRoi(self, tag)
            idx = self.findRoi(tag);
            self.selectedIdxs(end+1) = idx;
        end
        
        function unselectRoi(self, tag)
            idx = self.findRoi(tag);
            sidx = find(self.selectedIdxs == idx);
            if length(sidx)
                self.selectedIdxs(sidx) = [];
            end
            % sprintf('ROI #%d is not selected', tag) then do nothing
        end
        
        function rois = getSelectedRois(self)
            rois = self.roiList(self.selectedIdxs);
        end
        
        function idxs = getSelectedIdxs(self)
            idxs = self.selectedIdxs;
        end

        function tags = getSelectedTags(self)
            idxs = self.selectedIdxs;
            tags = self.tagList(idxs);
        end

        % Methods for groups
        
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
            % make sure group names are unique
            if ismember(groupName,self.groupNames)
                error('Group %s already exists!', groupName)
            end
            
            self.groupNames{end+1} = groupName;
            newTag = max([self.groupTags, 0]) + 1;
            self.groupTags = [self.groupTags, newTag];
        end
        
        function renameGroup(self, oldGroupName, newGroupName)
          idx = self.findGroupIdx(oldGroupName);
          self.groupNames{idx} = newGroupName;
          if strcmp(self.currentGroupName, oldGroupName)
              self.currentGroupName = newGroupName;
          end
        end

        function roi = assignRoiToGroupByIdx(self, idx, groupName)
            groupTag = self.findGroupTag(groupName);
            self.roiGroupTagList(idx) = groupTag;
            self.roiList(idx).meta.groupName = groupName;
            self.roiList(idx).meta.groupTag = groupTag;
            roi = self.roiList(idx);
        end
        
        function roi = assignRoiToGroup(self, tag, groupName)
            idx = self.findRoi(tag);
            roi = assignRoiToGroupByIdx(idx, groupName);
        end
        
        function roi = assignRoiToCurrentGroup(self, tag)
            roi = self.assignRoiToGroup(tag, self.currentGroupName);
        end
        
        function rois = assignRoisToGroupByIdx(self, idxs, groupName)
            rois = roiFunc.RoiM.empty();
            for k=1:length(idxs)
                rois(k) = self.assignRoiToGroupByIdx(idxs(k), groupName);
            end
        end
        
        function rois = assignSelectedRoisToCurrentGroup(self)
            rois = self.assignRoisToGroupByIdx(self.selectedIdxs, self.currentGroupName);
        end
        
        function rois = assignRoisToCurrentGroup(self, tags)
            rois = self.assignRoisToGroup(tags, self.currentGroupName);
        end

        function rois = assignRoisToGroup(self, tags, groupName)
            idxs = self.findRoisByTags(tags);
            rois = self.assignRoisToGroupByIdx(idxs, groupName);
        end

        function [rois, tags] = getSelectedRoisFromGroup(self, groupName)
            gidxs = self.findRoisInGroup(groupName);
            idxs = intersect(self.selectedIdxs, gidxs);
            rois = self.roiList(idxs);
            tags = self.tagList(idxs);
        end
        
        function idxs = findRoisInGroup(self, groupName)
            groupTag = self.findGroupTag(groupName);
            idxs = find(self.roiGroupTagList == groupTag);
        end
        
        function [rois, tags] = getRoisInGroup(self, groupName)
            idxs = self.findRoisInGroup(groupName);
            rois = self.roiList(idxs);
            tags = self.tagList(idxs);
        end
        
        
        function groupName = getRoiGroupName(self, tag)
            roi = self.getRoi(tag);
            groupName = roi.meta.groupName;
        end
        
        %% Mask functions
        function importFromMaskImg(self, maskImg, groupName)
            self.imageSize = size(maskImg);
            tagArray = unique(maskImg);
            tagArray(tagArray==0) = [];
            for k=1:length(tagArray)
                tag = tagArray(k);
                mask = maskImg == tag;
                % If the ROI contains multiple disconnected regions, only keep the largest one
                % Check the number of disconnected components
                CC = bwconncomp(mask);
                numComponents = CC.NumObjects;
                if numComponents > 1
                    disp(['Tag ' num2str(tag) ' has ' num2str(numComponents) ' disconnected components. Keeping only the largest.']);
                    % Keep only the largest connected component
                    stats = regionprops(CC, 'Area');
                    [~, largestIdx] = max([stats.Area]);
                    largestMask = false(size(mask));
                    largestMask(CC.PixelIdxList{largestIdx}) = true;
                    [mposY, mposX] = find(largestMask);
                else
                    % If there is only one component, use the original mask
                    [mposY, mposX] = find(mask);
                end
                position = [mposX'; mposY']';
                roi = roiFunc.RoiM('position', position,'tag',double(tag));
                self.addRoi(roi, groupName);
            end
        end
    
        function maskImg = convertToMask(self)
            maskImg = zeros(self.imageSize);
            for roi=self.roiList
                maskImg = min(maskImg + roi.createMask(self.imageSize)*roi.tag, roi.tag);
            end
        end
        
        function maskImg = convertToGroupMask(self)
            maskImg = zeros(self.imageSize);
            for k = 1:length(self.groupNames)
                groupName = self.groupNames(k);
                groupTag = self.groupTags(k);
                rois = self.getRoisInGroup(groupName);
                submask = zeros(self.imageSize);
                for roi=rois
                    submask = min(submask + roi.createMask(self.imageSize), 1);
                end
                maskImg = min(maskImg + submask*groupTag, groupTag);
            end
        end
        
        function roiArr = copy(self)
        % COPY copy self to a new RoiArray object
            roiArr = roiFunc.RoiArray();
            roiArr.copyFrom(self);
        end

        function copyFrom(self, roiArr)
        % COPYFROM copy the properties from the roiArr
            propsToCopy = {'imageSize',...
                           'currentGroupName',...
                           'groupNames',...
                           'roiList',...
                           'tagList',...
                           'roiGroupTagList',...
                           'selectedIdxs',...
                           'groupTags'};
            
            for k=1:length(propsToCopy)
                prop = propsToCopy{k};
                self.(prop) = roiArr.(prop);
            end
        end
        
    end
end

