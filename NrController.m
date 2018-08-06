classdef NrController < handle
    properties
        model
        view
        trialControllerArray
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(mymodel,self);
        end
        
        function addFilePath_Callback(self,filePath)
            self.model.addFilePath(filePath);
        end
        
        function fileListBox_Callback(self,src,evnt)
            fig = src.Parent;
            if strcmp(fig.SelectionType,'open')
                ind = src.Value;
                trial = self.model.getTrialByInd(ind);
                disp(trial)
            end
        end
    end
end
