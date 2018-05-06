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
        
        function addRoi(self,hObject)
            roi = ExtFreehandRoi();
            self.model.addRoi(roi);
        end
        % Bo Hu 2018-05-05
        function addRoiToggle(self,hObject)
            mapAxes = self.view.guiHandles.mapAxes;
            switch hObject.Value
              case hObject.Max 
                set(mapAxes,'ButtonDownFcn',@(src,evnt)self.addRoi());
              case hObject.Min
                set(mapAxes,'ButtonDownFcn','');
            end
        end
        
    end
end
