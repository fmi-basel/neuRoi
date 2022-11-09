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

        roiListboxOptionIdx

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
            
            %self.anatomyArray = anatomyArray;
            %self.responseArray = responseArray;
            self.mapSize = size(anatomyArray(:,:,1));
            self.mapType = 'anatomy';
            %self.nTrial = length(rawFileList);
            self.currentTrialIdx = 1;
            self.EditCheckbox=0;
            self.roiListboxOptionIdx=1;
            self.roiArrayNotOriginal=0;
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


        function deleteRoiAll(self)
            tagArray = self.selectedRoiTagArray;
            self.unselectAllRoi();
            indArray = self.findRoiByTagArray(tagArray);
            self.roiArray(indArray) = [];
%             currentRoiArray = self.roiArrays{ self.currentTrialIdx};
%             wantedRoi= cellfun(@(x) x.tag==RoiTag,currentRoiArray);
%             wantedRoiIndex=find(wantedRoi);
            for i=1:numel(self.roiArrays)
                wantedRoi= find(arrayfun(@(x) x.tag==tagArray,self.roiArrays{i}));
                self.roiArrays{i}(wantedRoi)=[];
            end
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(tagArray));
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
            self.getCurrentRoiArr().addRoi(roi, self.DIFF_NAME);
            self.allRoiTags(end+1) = roi.tag;
        end

        function addRoisInStack(self, groupName)
            if strcmp(groupName, self.DIFF_NAME)
                error('Diff group should not be used for containing common ROIs of a stack!')
            end
            roiArr = self.getCurrentRoiArr();
            [rois, tags] = roiArr().getSelectedRoisFromGroup(self.DIFF_NAME);
            transformInv = self.transformInvStack{self.currentTrialIdx};
            roiArr = roiFunc.RoiArray('roiList', rois, 'imageSize', roiArr.imageSize);
            templateRoiArr = BUnwarpJ.transformRoiArray(roiArr, transformInv);
            templateTags = templateRoiArr.getTagList();
            self.commonRoiTags = [self.commonRoiTags, templateTags];
            for k=1:self.nTrial
                transform = self.transformStack{k};
                troiArr = BUnwarpJ.transformRoiArray(templateRoiArr, transform);
                % TODO handle loss of ROI after transformation
                if k == self.currentTrialIdx
                    tags = troiArr.getTagList();
                    self.roiArrStack{k}.putRoisIntoGroup(tags, groupName)
                else

                    %roiArray =self.roiArrays{self.currentTrialIdx};
					self.roiArrStack{k}.addRois(troiArr.getRoiList(), groupName);
                end
            else
				%check if needed after merge
                roiArray=[];
            end
        end
        
        function SaveRoiArrayInRoiArrays(self)       
            self.roiArrays{ self.previousTrialIdx}= self.previousroiArray;
        end

        function SaveCurrentRoiArrayInRoiArrays(self)
            self.roiArrays{ self.currentTrialIdx}= self.roiArray;
        end

%         function SaveRoiArrayInRoiArrays(self, oldIdx)
%             self.roiArrays{oldIdx}=roiArray;
%         end
%         
      function mapSize = getMapSize(self)
           
                mapSize = size(self.anatomyArray(:,:,1));

      end

      function SaveRoiNormal(self)
        RoiPath=fullfile(self.resultDir,"BUnwarpJ",self.transformationName,"Rois.mat");
        OriginalPath=fullfile(self.resultDir,"BUnwarpJ",self.transformationName,"Rois-original.mat");
        if ~isfile(OriginalPath)
            copyfile(RoiPath,OriginalPath);
        end
        for i=1:length(self.roiArrays)
            RoiArray(i).roi=self.roiArrays{i};
            trialName=split(self.TransformationFiles{i},'.');
            trialName=trialName{1};
            RoiArray(i).trial=trialName;
        end
        save(RoiPath,"RoiArray");
      end
      
      function ExportRois(self)
          %pretty simple check if roi files exist; since first trial could
          %be added after the first export-but should be almost always
          %sufficient
          trialName=split(self.rawFileList{1},'.');
          trialName=trialName{1};
          filename=fullfile(self.resultDir,"roi",self.planeString,self.transformationName,strcat(trialName,self.roiFileIdentifier,".mat"));
          if isfile(filename)
              NewName=inputdlg("Please enter a new RoiFileIdentifier","Roi files with this identifier already exists");
              self.roiFileIdentifier=NewName;
              
          end
          mkdir(fullfile(self.resultDir,"roi",self.planeString,self.transformationName));
          for i=1:length(self.roiArrays)
            roiArray=self.roiArrays{i};
            trialName=split(self.rawFileList{i},'.');
            trialName=trialName{1};
            
            filename=fullfile(self.resultDir,"roi",self.planeString,self.transformationName,strcat(trialName,self.roiFileIdentifier,".mat"));
            %Not needed since transformation has individual folder
%             if i==self.transformationParameter.Reference_idx 
%             
%                 continue
%             end
            if isfile(filename)
                answer=questdlg(strcat('File ',trialName,' already exists',{newline},'Replace or rename(_2) the file to save?'),'File already exists','Replace','Rename','modal');
                switch answer
                    case 'Replace'
                        
                    case 'Rename'
                        filename=fullfile(self.resultDir,"roi",self.planeString,strcat(trialName,"_2",self.roiFileIdentifier,".mat"));

                end
                
            end
            save(filename,"roiArray");
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
                error('Too Many/few input args!')
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
        
        function selectMultiRoi(self, tagArray)
            self.unselectAllRoi();
            self.selectedRoiTagArray= tagArray;
            for k=1:length(tagArray)
                tag = tagArray(k); 
                notify(self,'roiSelected',NrEvent.RoiEvent(tag));
            end
            if length(tagArray)==1
                disp(sprintf('ROI #%d selected',tagArray))
            else
                disp('Multiple Rois selected')
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
        
      

       

        function updateRoi(self, tag, roi)
            self.getCurrentRoiArr().updateRoi(tag, roi)
        end
        
        function deleteRoi(self,tag)
            roiArr = self.getCurrentRoiArr();
            groupName = roiArr.getRoiGroupName(tag);
            roiArr.deleteRoi(tag)
            
            % If the ROI is in the common stack, record the deletion
            if ~strcmp(groupName, self.DIFF_NAME)
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
                    roiArr = self.roiArrStack{k};
                    roiArr.deleteRoi(tag);
                end
            end
        end
        
        function selectRois(self, tagLists)
            self.getCurrentRoiArr().selectRois(tagLists);
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
