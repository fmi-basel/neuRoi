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

        roiGroupStack
        commonRoiTags
        allRoiTags
        currentRoiGroup
        
        transformStack
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
            self.mapSize = size(self.anatomyStack(:, :, 1));

            if length(pr.roiArrStack)
                if pr.doSummarizeRoiTags
                    [self.commonRoiTags, self.allRoiTags] = self.summarizeRoiTags(pr.roiArrStack);
                else
                    self.allRoiTags = roiArrStack{1}.getAllTags();
                    self.commonRoiTags = self.allRoiTags;
                end
                self.roiGroupStack = self.separateCommonRois(pr.roiArrStack,...
                                                                  self.commonRoiTags);
            else
                self.allRoiTags = [];
                self.commonRoiTags = [];
                self.roiGroupStack = self.createEmptyRoiGroupStack(nTrial);
            end
            
            self.transformStack = pr.transformStack;
            self.templateIdx = pr.templateIdx; % templateIdx == inf means template is not in the stack
            
            self.currentTrialIdx = 1;
        end

        function selectTrial(self, trialIdx)
            self.currentTrialIdx = trialIdx;
        end
        
        function set.currentTrialIdx(self, idx)
            self.currentTrialIdx = idx;
            self.currentRoiGroup = self.roiGroupStack{idx};
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
        function addRoi(self, roi)
            roi.tag = self.getNewRoiTag();
            self.currentRoiGroup.addRoi(roi);
        end
        
        function tag = getNewRoiTag(self)
            tag = max(self.allRoiTags) + 1 
        end
        
        function updateRoi(self, tag, roi)
            self.currentRoiGroup.updateRoi(tag, roi)
        end
        
        function deleteRoi(self,tag)
            self.currentRoiGroup.deleteRoi(tag)
        end

        function deleteRoiAllTrials(self, tag)
            for k=1:self.nTrial
                roiArr = roiArrStack{k};
                roiArr.deleteRoi(tag)
            end
        end
        
        function addRoisAllTrial(self)
            rois = self.currentRoiGroup.getSelectedAddedRois();
            self.templateRoiArr.addRois()
            for k=1:self.nTrial
                transform = self.transformStack{k};
                trois = transformRois(rois, transform);
                self.roiArrStack{k}.addRois()
            end
            self.currentRoiGroup.deleteAddedRois(rois);
        end
    end

    methods
        function [commonTags, allTags] = summarizeRoiTags(self, roiArrStack)
            tagListStack = cellfun(@(x) x.getTagList(), roiArrStack,...
                                    'UniformOutput', false);
            commonTags = helper.multiIntersect(tagListStack);
            allTags = sort(unique(cell2mat(tagListStack)));
        end
        
        function roiGroupStack = separateCommonRois(self, roiArrStack, commonRoiTags)
            roiGroupStack = {};
            for k=1:length(roiArrStack)
                roiGroupStack{k} = self.splitRoiArr(roiArrStack{k}, commonRoiTags);
            end
        end
        
        function roiGroup = splitRoiArr(self, roiArr, tags)
            nameList = {'common', 'diff'};
            roiArrList = {};
            roiArrList{1} = roiArr.getRoisByTags(tags);
            allTags = roiArr.getTagList();
            otherTags = setdiff(allTags, tags);
            roiArrList{2} = roiArr.getRoisByTags(otherTags);
            roiGroup = roiFunc.RoiGroup(roiArrList, nameList);
        end
        
        function roiGroupStack = createEmptyRoiGroupStack(self, nTrial)
            roiGroupStack = {};
            for k=1:length(roiArrStack)
                nameList = {'common', 'diff'};
                roiArrList = {roiFunc.RoiArray('imageSize', self.mapSize),...
                              roiFunc.RoiArray('imageSize', self.mapSize)};
                roiGroupStack{k} = roiFunc.RoiGroup(roiArrList, nameList);
            end
        end
        
    end       
end
