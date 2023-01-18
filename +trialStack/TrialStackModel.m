classdef TrialStackModel < baseTrial.BaseTrialModel
    properties (Constant)
        DIFF_NAME = 'diff'
    end

    
    properties
        trialNameList
        trialIdxList
        anatomyStack
        responseStack
        nTrial
        
        mapLims
        contrastLimArray
        contrastForAllTrial
        mapTypeList
        mapSize

        roiArrStack
        commonRoiTags
        allRoiTags
        partialDeletedTags
        roiGroupName
        
        roiDir
        roiFilePath

        doTransform
        offsetYxList
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
            addOptional(pa,'offsetYxList', []);
            addOptional(pa,'templateIdx', inf);
            addParameter(pa, 'doSummarizeRoiTags', true)
            addParameter(pa, 'trialIdxList', [])
            addParameter(pa, 'roiDir', '')
            
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
            
            self.computeMapLims();
            self.contrastLimArray = cell(length(self.mapTypeList),...
                                         self.nTrial);
            self.contrastForAllTrial = false;
            self.mapSize = size(self.anatomyStack(:, :, 1));

            if length(pr.roiArrStack)
                if pr.doSummarizeRoiTags
                    [self.commonRoiTags, self.allRoiTags] = self.summarizeRoiTags(pr.roiArrStack);
                    self.roiArrStack = self.separateCommonRois(pr.roiArrStack,...
                                                               self.commonRoiTags);
                else
                    self.allRoiTags = roiArrStack(1).getTagList();
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
                self.offsetYxList = pr.offsetYxList;
                self.templateIdx = pr.templateIdx; % templateIdx == inf means template is not in the stack
            else
                self.doTransform = false;
            end
            
            if length(pr.trialIdxList)
                self.trialIdxList = pr.trialIdxList;
            end
            
            self.currentTrialIdx = 1;
            self.roiGroupName = 'default';
            
            self.roiDir = pr.roiDir;
        end

        function set.currentTrialIdx(self, trialIdx)
            self.currentTrialIdx = trialIdx;
            self.roiArr = self.roiArrStack(self.currentTrialIdx);
        end
        
        function data = getMapData(self,mapType,trialIdx)
            switch mapType
              case 'anatomy'
                mapStack = self.anatomyStack;
              case 'response'
                mapStack = self.responseStack;
            end
            data = mapStack(:, :, trialIdx);
        end
        
        function map = getCurrentMap(self)
            map.data = self.getMapData(self.mapType,self.currentTrialIdx);
            map.type = self.mapType;
            map.option.trialIdx = self.currentTrialIdx;
            if self.trialIdxList
                map.option.origTrialIdx = self.trialIdxList(self.currentTrialIdx);
            end
            map.option.fileName = self.trialNameList{self.currentTrialIdx};
        end
        
        function computeMapLims(self)
            self.mapLims = zeros(length(self.mapTypeList), 2);
            
            self.mapLims(1, :) = helper.minMax(self.anatomyStack);
            self.mapLims(2, :) = helper.minMax(self.responseStack);
        end
        
        function saveContrastLim(self,contrastLim)
            mapTypeIdx = self.findMapTypeIdx(self.mapType);
            if self.contrastForAllTrial
                [self.contrastLimArray{mapTypeIdx,:}] = deal(contrastLim);
            else
                self.contrastLimArray{mapTypeIdx,self.currentTrialIdx} = contrastLim;
            end
        end
        
        function [dataLim, contrastLim] = getDataLimAndContrastLim(self)
            mapTypeIdx = self.findMapTypeIdx(self.mapType);
            if self.contrastForAllTrial
                dataLim = self.mapLims(mapTypeIdx, :);
            else
                map = self.model.getCurrentMap();
                dataLim = helper.minMax(map.data);
                sn = 10000*eps; % a small number
                dataLim(2) = dataLim(2) + sn;
            end
            
            contrastLim = self.contrastLimArray{mapTypeIdx,self.currentTrialIdx};
            if isempty(contrastLim)
                contrastLim = dataLim;
            else
                ss = helper.rangeIntersect(dataLim,contrastLim);
                if ~isempty(ss)
                    contrastLim = ss;
                else
                    contrastLim = dataLim;
                end
            end
            self.saveContrastLim(contrastLim);
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
        % Methods for ROIs
        function tag = getNewRoiTag(self)
            tag = max(self.allRoiTags) + 1;
        end
        
        function addRoi(self, roi)
            roi.tag = self.getNewRoiTag();
            self.roiArr.addRoi(roi, self.DIFF_NAME);
            self.allRoiTags(end+1) = roi.tag;
            notify(self, 'roiAdded')
        end

        function addRoisInStack(self, groupName)
            if strcmp(groupName, self.DIFF_NAME)
                error('Diff group should not be used for containing common ROIs of a stack!')
            end
            % TODO TODO carefully handle the transformation!!
            % TODO write proper test
            [rois, tags] = self.roiArr.getSelectedRoisFromGroup(self.DIFF_NAME);
            offsetYx = self.offsetYxList(self.currentTrialIdx, :);
            transformInv = self.transformInvStack(self.currentTrialIdx);
            
            roiArr = roiFunc.RoiArray('roiList', rois, 'imageSize', self.roiArr.imageSize);
            templateRoiArr = Bunwarpj.transformRoiArray(roiArr, transformInv, offsetYx);
            templateTags = templateRoiArr.getTagList();
            self.commonRoiTags = [self.commonRoiTags, templateTags];
            
            troiArrStack = Bunwarpj.transformRoiArrStack(templateRoiArr, self.transformStack, -self.offsetYxList);

            % TODO handle loss of ROI after transformation
            for k = 1:self.nTrial
                if k == self.currentTrialIdx
                    tags = troiArrStack(k).getTagList();
                    self.roiArrStack(k).putRoisIntoGroup(tags, groupName);
                else
                    self.roiArrStack(k).addRois(troiArrStack(k).getRoiList(), groupName);
                end
            end
        end

        function updateRoi(self, tag, roi)
            self.roiArr.updateRoi(tag, roi)
        end
        
        function roi = deleteRoi(self,tag)
            groupName = self.roiArr.getRoiGroupName(tag);
            roi = self.roiArr.deleteRoi(tag);
            
            % If the ROI is in the common stack, record the deletion
            if ~strcmp(groupName, self.DIFF_NAME)
                self.partialDeletedTags{end+1} = [self.currentTrialIdx, tag];
            end
        end

        function roiStack = deleteRoiInStack(self, tag)
            cidx = find(self.commonRoiTags == tag);
            if cidx
                self.commonRoiTags(cidx) = [];
            else
                error(sprintf('ROI #%d not found in common ROIs of the stack!', tag))
            end
            aidx = find(self.allRoiTags == tag);
            self.allRoiTags(aidx) = [];

            roiStack = {};
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
                    roiArr = self.roiArrStack(k);
                    roi = roiArr.deleteRoi(tag);
                    roiStack{k} = roi;
                end
            end
        end
        
        function deleteSelectedRois(self)
            tags = self.roiArr.getSelectedTags();
            rois = roiFunc.RoiM.empty();
            for k=1:length(tags)
                tag = tags(k);
                rois(k) = self.deleteRoi(tag);
            end
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(rois));
            % TODO save ROIs temporarily for undo
        end
        
        function deleteSelectedRoisInStack(self)
            tags = self.roiArr.getSelectedTags();
            roiStacks = {}
            for k=1:length(tags)
                tag = tags(k);
                roiStacks{k} = self.deleteRoiInStack(tag);
            end
            % Only notify the deleted ROIs in current trial
            rois = roiFunc.RoiM.empty();
            for k=1:length(tags)
                roi = roiStacks{k}{self.currentTrialIdx}
                if ~isempty(roi)
                    rois(k) = roi;
                end
            end
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(rois));
            % TODO save ROIs temporarily for undo
        end
        
        function undoDeleteRoi()
        end
        
        function undoDeleteRoiInStack()
        end
        
        function undoUpdateRoi()
        end
        
        function saveRoiArrStack(self, filePath)
            roiArrStack = self.roiArrStack;
            save(filePath, 'roiArrStack');
            self.roiFilePath = filePath;
        end
    end
    
    % Methods for initializing roiStack
    methods
        function [commonTags, allTags] = summarizeRoiTags(self, roiArrStack)
            tagListStack = arrayfun(@(x) x.getTagList(), roiArrStack,...
                                    'UniformOutput', false);
            commonTags = helper.multiIntersect(tagListStack);
            allTags = sort(unique(cell2mat(tagListStack)));
        end
        
        function sroiArrStack = separateCommonRois(self, roiArrStack, commonRoiTags)
            sroiArrStack = roiFunc.RoiArray.empty();
            for k=1:length(roiArrStack)
                sroiArrStack(k) = self.splitRoiArr(roiArrStack(k), commonRoiTags);
            end
        end
        
        function roiArr = splitRoiArr(self, roiArr, tags)
            allTags = roiArr.getTagList();
            diffTags = setdiff(allTags, tags);
            roiArr.addGroup('diff')
            if length(diffTags)
                roiArr.putRoisIntoGroup(diffTags, 'diff')
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
