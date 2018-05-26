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
            freshRoi = ExtFreehandRoi();
            if ~isempty(freshRoi.getPosition())
                self.model.addRoi(freshRoi);
            else
                delete(freshRoi)
            end
        end
        
        function selectRoi(self)
            selectedObj = get(gco,'Parent');
            tag = get(selectedObj,'Tag');
            if and(~isempty(selectedObj),strfind(tag,'roi_'))
                self.model.setCurrentRoiByTag(tag);
            end 

        end
        
        function deleteRoi(self)
            self.model.deleteRoi()
        end
        
        function roiPos = copyRoiPos(self)
            currentRoi = self.model.currentRoi;
            roiPos = currentRoi.getPosition();
        end
        
        function pasteRoi(self,roiPos)
        % TODO
            if ~isempty(roiPos)
                freshRoi = imfreehand(roiPos);
                self.model.addRoi(freshRoi);
            else
                warning('Empty ROI!')
            end
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
