classdef TrialStackModel < handle
    properties
        rawFileList
        anatomyArray
        responseArray
        mapSize
        nTrial
        
        contrastLimArray
        contrastForAllTrial
        mapTypeList
        templateRoiArray
        roiArrayStack
        roiArray
        SingleRoi

        transformationParameter
        transformationName
        transformDir
    end
    
    properties (SetObservable)
        currentTrialIdx
        mapType
        roiVisible
        selectedRoiTagArray
    end

    events
        loadNewRois
        roiAdded
        roiDeleted
        roiUpdated
        roiArrayReplaced
        roiTagChanged
        
        roiSelected
        roiUnSelected
        roiSelectionCleared

        roiNewAlpha
        roiNewAlphaAll
    end
    
    methods
        function self = TrialStackModel(rawFileList,templateRoiArray,...
                                        anatomyArray,...
                                        responseArray,...
                                        transformationParameter,transformationName,...
                                        transformDir,...
                                        roiArrayStack)
            % TODO check sizes of all arrays
            self.rawFileList = rawFileList;
            self.anatomyArray = anatomyArray;
            self.responseArray = responseArray;
            self.mapSize = size(anatomyArray(:,:,1));
            self.mapType = 'anatomy';
            self.nTrial = length(rawFileList);
            self.currentTrialIdx = 1;
            self.mapTypeList = {'anatomy','response'};
            self.contrastLimArray = cell(length(self.mapTypeList),...
                                         self.nTrial);
            self.contrastForAllTrial = false;
            
            self.templateRoiArray = templateRoiArray;
            self.transformDir = transformDir;
            
            if exist('roiArrayStack','var')
                self.roiArrayStack=roiArrayStack;
            else
                self.transformTemplateRoiArray();
            end
            
            if exist('transformationParameter','var')
                self.transformationParameter=transformationParameter;
            else
                self.transformationParameter=string();
            end
            if exist('transformationName','var')
                self.transformationName=transformationName;
            end
        end
        
        function transformTemplateRoiArray(self)
            self.roiArrayStack = BUnwarpJ.transformRoiArray(self.templateRoiArray,self.mapSize,...
                                                            self.rawFileList, self.transformDir);
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
        
        function MaxTrialnumber = getMaxTrialnumber(self)
            MaxTrialnumber = length(self.anatomyArray(1,1,:));
        end

        
        function idx = findMapTypeIdx(self, mapType)
            idx = find(strcmp(self.mapTypeList, self.mapType));
        end
        
        function set.currentTrialIdx(self,idx)
            newIdx = min(max(idx,1),length(self.rawFileList));
            self.currentTrialIdx = newIdx;
            self.roiArray= self.getCurrentRoiArray();
        end
        
        function selectMapType(self,idx)
           self.mapType = self.mapTypeList{idx};
        end
        
        function roiArray = getCurrentRoiArray(self)
            if length(self.roiArrayStack)
                roiArray =self.roiArrayStack(self.currentTrialIdx).roi;
            else
                roiArray=[];
            end
        end
     % Methods for ROI-based processing
        % TODO set roiArray to private
        function addRoi(self,varargin)
        % ADDROI add ROI to ROI array
        % input arguments can be a RoiFreehand object
        % or a structure containing position and imageSize
            
            if nargin == 2
                if isa(varargin{1},'RoiFreehand')
                    roi = varargin{1};
                else
                    % TODO add ROI from mask
                    error('Wrong usage!')
                    help TrialModel.addRoi
                end
            else
                error('Wrong usage!')
                help TrialModel.addRoi
            end
            
            nRoi = length(self.roiArray);
            if nRoi >= self.MAX_N_ROI
                error('Maximum number of ROIs exceeded!')
            end
            
            % TODO validate ROI position (should not go outside of image)
            if isempty(self.roiArray)
                roi.tag = 1;
            else
                roi.tag = self.roiTagMax+1;
            end
            self.roiTagMax = roi.tag;
            self.roiArray(end+1) = roi;
            
            notify(self,'roiAdded')
        end
        
        function selectSingleRoi(self,varargin)
            if nargin == 2
                if strcmp(varargin{1},'last')
                    ind = length(self.roiArray);
                    tag = self.roiArray(ind).tag;
                else
                    tag = varargin{1};
                    ind = self.findRoiByTag(tag);
                end
            else
                error('Too many/few input args!')
            end
            
            if ~isequal(self.selectedRoiTagArray,[tag])
                self.unselectAllRoi();
                self.selectRoi(tag);
            end
        end
        
        function selectRoi(self,tag)
            if ~ismember(tag,self.selectedRoiTagArray)
                ind = self.findRoiByTag(tag);
                self.selectedRoiTagArray(end+1)  = tag;
                notify(self,'roiSelected',NrEvent.RoiEvent(tag));
                disp(sprintf('ROI #%d selected',tag))
            end
        end
        
        function unselectRoi(self,tag)
            tagArray = self.selectedRoiTagArray;
            tagInd = find(tagArray == tag);
            if tagInd
                self.selectedRoiTagArray(tagInd) = [];
                notify(self,'roiUnSelected',NrEvent.RoiEvent(tag));
            end
        end
        
        function tagArray = getAllRoiTag(self)
        % TODO remove uniform false
        % Debug tag data type (uint16 or double)
            tagArray = arrayfun(@(x) x.tag, self.roiArray);
        end
        
        function selectAllRoi(self)
            tagArray = self.getAllRoiTag();
            self.unselectAllRoi();
            self.selectedRoiTagArray = tagArray;
            for k=1:length(tagArray)
                tag = tagArray(k);
                notify(self,'roiSelected',NrEvent.RoiEvent(tag));
            end
            disp('All Rois selected')
        end
        
        function unselectAllRoi(self)
            self.selectedRoiTagArray = [];
            notify(self,'roiSelectionCleared');
        end


        function NewAlphaAllRois(self, NewAlpha)
            arguments
                self
                NewAlpha {mustBeInRange(NewAlpha,0,1)}
            end
            for  i=1:length(self.roiArray)
                self.roiArray(i).AlphaValue=NewAlpha;
            end
            notify(self,'roiNewAlphaAll', ...
                   NrEvent.RoiNewAlphaEvent({},true,NewAlpha));
           % self.NewAlphaRois(self.roiArray,NewAlpha);
        end

        function NewAlphaRois(self,selectedRois,NewAlpha)
            arguments
                self 
                selectedRois (1,:) RoiFreehand
                NewAlpha {mustBeInRange(NewAlpha,0,1)}
            end
            for  i=1:length(selectedRois)
                selectedRois(i).AlphaValue=NewAlpha;
            end
            notify(self,'roiNewAlpha', ...
                   NrEvent.RoiNewAlphaEvent(selectedRois));
        end
        
        function updateRoi(self,tag,varargin)
            ind = self.findRoiByTag(tag);
            oldRoi = self.roiArray(ind);
            freshRoi = RoiFreehand(varargin{:});
            freshRoi.tag = tag;
            % TODO validate ROI position (should not go outside of image)
            self.roiArray(ind) = freshRoi;

            notify(self,'roiUpdated', ...
                   NrEvent.RoiUpdatedEvent([self.roiArray(ind)]));
            disp(sprintf('Roi #%d updated',tag))
        end
        
        function changeRoiTag(self,oldTag,newTag)
            ind = self.findRoiByTag(oldTag);
            oldRoi = self.roiArray(ind);
            tagArray = self.getAllRoiTag();
            if ismember(newTag,tagArray)
                error(['New tag cannot be assigned! The tag is ' ...
                       'already used by another ROI.'])
            else
                oldRoi.tag = newTag;
                self.roiArray(ind) = oldRoi;
                notify(self,'roiTagChanged', ...
                NrEvent.RoiTagChangedEvent(oldTag,newTag));
                disp(sprintf('Roi #%d changed to #%d',oldTag,newTag))
                if ismember(oldTag,self.selectedRoiTagArray)
                    idx = find(self.selectedRoiTagArray,oldTag);
                    self.selectedRoiTagArray(idx) = newTag;
                end
            end
        end
        
        function deleteSelectedRoi(self)
            tagArray = self.selectedRoiTagArray;
            self.unselectAllRoi();
            indArray = self.findRoiByTagArray(tagArray);
            self.roiArray(indArray) = [];
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(tagArray));
        end
        
        function deleteRoi(self,tag)
            ind = self.findRoiByTag(tag);
            self.unselectRoi(tag);
            self.roiArray(ind) = [];
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent([tag]));loadRoiArray
        end
        
        function roiArray = getRoiArray(self)
            roiArray = self.roiArray;
        end
        
        function roi = getRoiByTag(self,tag)
            if strcmp(tag,'end')
                roi = self.roiArray(end);
            else
                ind = self.findRoiByTag(tag);
                roi = self.roiArray(ind);
            end
        end
        

        function insertRoiArray(self,roiArray,option)
            if strcmp(option,'merge')
                arrayfun(@(x) self.addRoi(x),roiArray);
            elseif strcmp(option,'replace')
                self.roiArray = roiArray;
                tagArray = self.getAllRoiTag();
                self.roiTagMax = max(tagArray);
                notify(self,'roiArrayReplaced');
            end
        end
        
        function saveRoiArrayStack(self)
            roiDir = fullfile(self.transformDir, 'roi');
            filePath = fullfile(roiDir, 'roiArrayStack.mat');
            save(filePath, self.roiArrayStack)
        end
        
        function saveTrialStack(self)
            stackFile = fullfile(self.transformDir, 'trial_stack.mat')
            save(stackFile, 'self')
        end
    end
end

