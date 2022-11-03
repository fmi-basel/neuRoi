classdef TrialStackModel < handle
    properties
        trialNameList
        anatomyStack
        responseStack
        nTrial
        
        contrastLimArray
        contrastForAllTrial
        mapTypeList
        mapSize

        roiArrStack
        commonRoiTags
        allRoiTags
        partialDeletedTags
        DIFF_NAME = 'diff'

        doTransform
        transformStack
        transformInvStack
        templateIdx
    end
    
    properties (SetObservable)
        currentTrialIdx
        mapType
        roiVisible
    end

    methods
        function self = TrialStackModel(trialNameList,...
                                        anatomyStack,...
                                        responseStack,...
                                        varargin)
            pa = inputParser;
            addRequired(pa,'trialNameList');
            addRequired(pa,'anatomyStack');
            addRequired(pa,'responseStack');
            addOptional(pa,'roiArrStack', []);
            addOptional(pa,'transformStack', []);
            addOptional(pa,'transformInvStack', []);
            addOptional(pa,'templateIdx', inf);
            addParameter(pa, 'doSummarizeRoiTags', true)
            
            parse(pa,trialNameList,...
                  anatomyStack,...
                  responseStack,...
                  varargin{:})
            pr = pa.Results;

            % TODO check sizes of all arrays
            self.trialNameList = pr.trialNameList;
            self.anatomyStack = pr.anatomyStack;
            self.responseStack = pr.responseStack;
            self.nTrial = length(trialNameList);
            self.mapTypeList = {'anatomy','response'};
            self.mapType = 'anatomy';
            self.contrastLimArray = cell(length(self.mapTypeList),...
                                         self.nTrial);
            self.contrastForAllTrial = false;
            self.mapSize = size(self.anatomyStack{1});

            if length(pr.roiArrStack)
                if pr.doSummarizeRoiTags
                    [self.commonRoiTags, self.allRoiTags] = self.summarizeRoiTags(pr.roiArrStack);
                    self.roiArrStack = self.separateCommonRois(pr.roiArrStack,...
                                                               self.commonRoiTags);
                else
                    self.allRoiTags = roiArrStack{1}.getTagList();
                    self.commonRoiTags = self.allRoiTags;
                    self.roiArrStack = pr.roiArrStack;
                end
                
            else
                self.allRoiTags = [];
                self.commonRoiTags = [];
                self.roiArrStack = self.createEmptyRoiArrStack(self.nTrial);
            end
            self.partialDeletedTags = {};
            
            if length(pr.transformStack)
                self.doTransform = true;
                self.transformStack = pr.transformStack;
                self.transformInvStack = pr.transformInvStack;
                self.templateIdx = pr.templateIdx; % templateIdx == inf means template is not in the stack
            else
                self.doTransform = false;
            end
            
            self.currentTrialIdx = 1;
        end

        function selectTrial(self, trialIdx)
            self.currentTrialIdx = trialIdx;
        end
        
            
        function data = getMapData(self,mapType,trialIdx)
            switch mapType
              case 'anatomy'
                mapArray = self.anatomyArray;
              case 'response'
                mapArray = self.responseArray;
            end
            data = mapArray(:,:,trialIdx);
        end
        
        function map = getCurrentMap(self)
            map.data = self.getMapData(self.mapType,self.currentTrialIdx);
            map.type = self.mapType;
            map.meta.trialIdx = self.currentTrialIdx;
            
            map.meta.fileName = self.rawFileList{self.currentTrialIdx};
            contrastLim = self.getContrastLimForCurrentMap();
            if isempty(contrastLim)
                contrastLim = helper.minMax(map.data);
                self.saveContrastLim(contrastLim);
            end
            map.contrastLim = contrastLim;
        end
        
        function saveContrastLim(self,contrastLim)
            mapTypeIdx = self.findMapTypeIdx(self.mapType);
            if self.contrastForAllTrial
                [self.contrastLimArray{mapTypeIdx,:}] = deal(contrastLim);
            else
                self.contrastLimArray{mapTypeIdx,self.currentTrialIdx} = contrastLim;
            end
        end
        
        function climit = getContrastLimForCurrentMap(self)
            mapTypeIdx = self.findMapTypeIdx(self.mapType);
            climit = self.contrastLimArray{mapTypeIdx,self.currentTrialIdx};
        end
        
        function idx = findMapTypeIdx(self, mapType)
            idx = find(strcmp(self.mapTypeList, self.mapType));
        end
        
        function selectMapType(self,idx)
           self.mapType = self.mapTypeList{idx};
        end
        
        function saveTrialStack(self, filePath)
            save(filePath, 'self')
        end
    end
    
    methods
        function roiArr = getCurrentRoiArr(self)
            roiArr = self.roiArrStack{self.currentTrialIdx};
        end
        
        function tag = getNewRoiTag(self)
            tag = max(self.allRoiTags) + 1;
        end
        
        function addRoi(self, roi)
            roi.tag = self.getNewRoiTag();
            roi.setMeta('groupName', self.DIFF_NAME);
            self.getCurrentRoiArr().addRoi(roi, 'groupName', self.DIFF_NAME);
            self.allRoiTags(end+1) = roi.tag;
        end

        function addRoisInStack(self)
            roiArr = self.currentRoiArr.getSelectedRoisFromGroup(DIFF_NAME);
            tags = roiArr.getTagList();
            transformInv = self.transformInvStack{self.currentTrialIdx};
            templateRoiArr = BUnwarpJ.transformRoiArray(roiArr, transformInv);
            templateTags = templateRoiArr.getTagList();
            self.commonRoiTags = [self.commonRoiTags, templateTags];
            for k=1:self.nTrial
                transform = self.transformStack{k};
                troiArr = BUnwarpJ.transformRoiArray(templateRoiArr, transform);
                self.roiArrStack{k}.addRois(troiArr.getRoiList(), self.groupIdx);
            end
            self.currentRoiArr.deleteRois(tags);
        end

        function updateRoi(self, tag, roi)
            self.currentRoiArr.updateRoi(tag, roi, self.groupIdx)
        end
        
        function deleteRoi(self,tag)
            self.currentRoiArr.deleteRoi(tag, self.groupIdx)
            
            % If the ROI is in the common stack, record the deletion
            if self.groupIdx == 1
                self.partialDeletedTags{end+1} = [self.currentTrialIdx, tag];
            end
        end

        function deleteRoiInStack(self, tag)
            cidx = find(self.commonRoiTags == tag);
            if cidx
                self.commonRoiTags(cidx) = [];
            else
                error(sprintf('ROI #%d not found in common ROIs of the stack!', tag))
            end
            aidx = find(self.allRoiTags == tag);
            self.allRoiTags(aidx) = [];

            for k=1:self.nTrial
                trialTagPair = [k, tag];
                
                % If the ROI is deleted in the trial already
                % skip deletion and remove the record of partial deletion
                if length(self.partialDeletedTags)
                    pidx = find(isequal(self.partialDeletedTags{:}, trialTagPair));
                else
                    pidx = [];
                end
                
                if length(pidx)
                    self.partialDeletedTags(pidx) = [];
                else
                    roiCollect = self.roiCollectStack{k};
                    roiCollect.deleteRoi(tag, 1);
                end
            end
        end
        
        function selectRois(self, groupIdxs, tagLists)
            self.currentRoiCollect.selectRois(groupIdxs, tagLists);
        end
    end

    methods
        function [commonTags, allTags] = summarizeRoiTags(self, roiArrStack)
            tagListStack = cellfun(@(x) x.getTagList(), roiArrStack,...
                                    'UniformOutput', false);
            commonTags = helper.multiIntersect(tagListStack);
            allTags = sort(unique(cell2mat(tagListStack)));
        end
        
        function sroiArrStack = separateCommonRois(self, roiArrStack, commonRoiTags)
            sroiArrStack = {};
            for k=1:length(roiArrStack)
                sroiArrStack{k} = self.splitRoiArr(roiArrStack{k}, commonRoiTags);
            end
        end
        
        function roiArr = splitRoiArr(self, roiArr, tags)
            allTags = roiArr.getTagList();
            diffTags = setdiff(allTags, tags);
            roiArr.addGroup('diff')
            if length(diffTags)
                roiArr.setRoiGroup(diffTags, 'diff')
            end
        end
        
        function roiCollectStack = createEmptyRoiArrStack(self, nTrial)
            roiArrStack = {};
            for k=1:nTrial
                roiArrStack{k} = roiFunc.RoiArray('imageSize', self.mapSize);
                roiArrStack{k}.addGroup('diff')
            end
        end
        
    end       
end
