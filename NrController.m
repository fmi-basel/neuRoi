classdef NrController < handle
    properties
        model
        view
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(self);
        end
        
        function setDisplayState(self,displayState)
            if ismember(displayState, self.model.stateArray)
                if strcmp(displayState,'localCorr') & ~self.model.localCorrMap
                        self.model.calcLocalCorrelation();
                end
                self.model.displayState = displayState;
            else
                error('The state should be in array of states')
            end
        end
        
        % ROI funcitons
        function addRoi(self)
            rawRoi = imfreehand;
            position = rawRoi.getPosition();
            delete(rawRoi)
            imageInfo = getImageSizeInfo(self.view.guiHandles.mapImage);
            if ~isempty(position)
                freshRoi = RoiFreehand(0,position,imageInfo);
                self.model.addRoi(freshRoi);
                self.view.addRoiPatch(freshRoi);
                self.model.currentRoi = freshRoi;
            end
        end
                
        function selectRoi(self)
            selectedObj = gco; % get(gco,'Parent');
            tag = get(selectedObj,'Tag');
            if and(~isempty(selectedObj),strfind(tag,'roi_'))
                slRoi = getappdata(selectedObj,'roiHandle');
                self.model.currentRoi = slRoi;
            end 
        end
        
        function deleteRoi(self)
            display('Control:delete')
            selectedObj = gco;
            tag = get(selectedObj,'Tag');
            if and(~isempty(selectedObj),strfind(tag,'roi_'))
                slRoi = getappdata(selectedObj,'roiHandle');
                self.model.deleteRoi(slRoi);
                self.view.deleteRoiPatch(selectedObj);
            end 
        end
        
        function roi = copyRoi(self)
            currentRoi = self.model.currentRoi;
            roi = copy(currentRoi)
        end
        
        function pasteRoi(self,roi)
            if isvalid(roi) && isa(roi,'RoiFreehand')
                % TODO check if image info matches
                self.model.addRoi(roi);
                self.view.addRoiPatch(roi);
                self.model.currentRoi = roi;
            else
                warning('Invalid ROI!')
            end
        end
        
        function addRoiArray(self,roiArray)
            self.model.addRoiArray(roiArray);
            self.view.addRoiPatchArray(roiArray);
        end

        function saveRoiArray(self,filePath)
            NrModel.saveRoiArray(self.model,filePath)
        end
        
        function loadRoiArray(self,filePath)
            foo = load(filePath);
            roiArray = foo.roiArray;
            self.addRoiArray(roiArray);
        end
        
        
    end
    
    methods
        function closeGUI(self,src,event)
            selection = questdlg('Close MyGUI?', ...
                                 'Warning', ...
                                 'Yes','No','Yes');
            switch selection
              case 'Yes'
                delete(src)
              case 'No'
                return
            end
        end
    end

end
