classdef TrialStackModel < handle
    properties
        trialNameList
        anatomyStack
        responseStack
        mapSize
        nTrial
        
        contrastLimArray
        contrastForAllTrial
        mapTypeList

        templateRoiArr
        roiArrStack
        
        transformStack
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
                                        templateRoiArr,...
                                        roiArrStack,...
                                        modRoiArrStack,...
                                        transformStack,...
                                        templateIdx)
        % TODO templateRoiArray
            % TODO check sizes of all arrays
            self.rawFileList = rawFileList;

            %apply CLAHE
            for i=1:size(anatomyArray,3)
                anatomyArray(:,:,i)=adapthisteq(uint8(squeeze(anatomyArray(:,:,i))),"NumTiles",[8 8],'ClipLimit',0.02);
            end
            
            self.anatomyArray = anatomyArray;
            self.responseArray = responseArray;
            self.mapSize = size(anatomyArray(:,:,1));
            self.mapType = 'anatomy';
            self.nTrial = length(rawFileList);
            self.currentTrialIdx = 1;
            self.EditCheckbox=0;
            self.roiArrayNotOriginal=0;
            self.mapTypeList = {'anatomy','response'};
            self.contrastLimArray = cell(length(self.mapTypeList),...
                                         self.nTrial);
            self.contrastForAllTrial = false;
            if ~exist('roiArrays','var')
                self.roiProvided= false;
            else
                self.roiArrays=roiArrays;
                self.roiProvided=true;
                roiSize=length(roiArrays);
                if roiSize(1)==1
                    self.SingleRoi=true;
                    self.roiArray=roiArrays;
                else
                    self.SingleRoi=false;
                    if roiSize(1)~=self.nTrial
                        self.roiArrays= [];
                        self.roiProvided=false;
                    else
                        self.roiArray=roiArrays{1};
                    end
                end
             end
            if exist('transformationParameter','var')
                self.transformationParameter=transformationParameter;
                if isfield(self.transformationParameter,"Rawfile_List")
                    self.containsRawFileList=true;
                else
                    self.containsRawFileList=false;
                end
                if isfield(self.transformationParameter,"RoiFileIdentifier")
                    self.roiFileIdentifier=self.transformationParameter.RoiFileIdentifier;
                else
                    self.roiFileIdentifier="_RoiArray";
                end
            else
                self.transformationParameter=string();
            end
            if exist('transformationName','var')
                self.transformationName=transformationName;
            end
            self.currentTrialIdx = 1;
            % self.roiSavedStatus=true;
        end
        
        function transformTemplateRoiArray(self)
            self.roiArrayStack = BUnwarpJ.transformRoiArray(self.templateRoiArray,self.mapSize,...
                                                            self.rawFileList, self.transformDir);
        end
        
        function deleteRoiCurrent(self)
            tagArray = self.selectedRoiTagArray;
            self.unselectAllRoi();
            indArray = self.findRoiByTagArray(tagArray);
            self.roiArray(indArray) = [];
            self.roiArrays{ self.currentTrialIdx}=self.roiArray;
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(tagArray));
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
        

        function addRoi(self, roi)
            roi.tag = xxx % TODO from templateRoiArr
            self.currentRoiArr.addRoi(roi)
        end
        
        function updateRoi(self, tag, roi)
            self.currentRoiArr.updateRoi(tag, roi)
        end
        
        function deleteRoi(self,tag)
            self.currentRoiArr.deleteRoi(tag)
        end

        function deleteRoiAllTrials(self)
        end
        
        function addRoisAllTrial(self)
            rois = self.currentRoiArr.getSelectedAddedRois();
            self.templateRoiArr.addRois()
            for k=1:self.nTrial
                transform = self.transformStack{k};
                trois = transformRois(rois, transform);
                self.roiArrStack{k}.addRois()
            end
            self.currentRoiArr.deleteAddedRois(rois);
        end
        
        
        function saveTrialStack(self)
            stackFile = fullfile(self.transformDir, 'trial_stack.mat')
            save(stackFile, 'self')
        end
    end
end

