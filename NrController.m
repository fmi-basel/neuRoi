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
        
        function setLoadMovieOption(self,loadMovieOption)
            self.model.loadMovieOption = loadMovieOption;
        end
        
        function addFilePath_Callback(self,filePath)
            self.model.addFilePath(filePath);
        end
        
        function fileListBox_Callback(self,src,evnt)
            fig = src.Parent;
            if strcmp(fig.SelectionType,'open')
                ind = src.Value;
                trial = self.model.getTrialByInd(ind);
                if isempty(trial)
                    self.model.loadTrial(ind);
                    trial = self.model.getTrialByInd(ind);
                    trialController = TrialController(trial);
                    trialController.addMap('anatomy');
                    trialControllerArray{ind} = trialController;
                else
                    disp('trial exist,will raise the trial window')
                end
            end
        end
    end
end
