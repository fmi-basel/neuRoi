classdef TrialController < handle
    properties
        model
        view
        nMapMax
    end
    methods
        function self = TrialController(mymodel)
            self.model = mymodel;
            self.nMapMax = 6;
            self.view = TrialView(self.model,self);
        end
        
        function addMap(self,type,varargin)
            mapArrayLen = self.model.getMapArrayLength();
            if mapArrayLen >= self.nMapMax
                error('Cannot add more than %d maps',nMapButton);
            end
            self.model.calculateAndAddNewMap(type,varargin{:});
            self.model.selectMap(mapArrayLen+1);
        end
        
        function mapButtonSelected_Callback(self,src,evnt)
            tag = evnt.NewValue.Tag;
            ind = helper.convertTagToInd(tag,'mapButton');
            self.model.selectMap(ind);
        end
        
        function setFigTagPrefix(self,prefix)
            self.view.setFigTagPrefix(prefix);
        end
        
        function raiseView(self)
            self.view.raiseFigures();
        end
        
        function mainFigClosed_Callback(self,src,evnt)
            self.view.deleteFigures();
            delete(self.view);
            delete(self.model);
            delete(self);
        end
        
        function delete(self)
            if isvalid(self.view)
                self.view.deleteFigures();
                delete(self.view)
            end
        end
    end
end
