classdef NrController < handle
    properties
        model
        view
        trialControllerArray
        rootListener
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(mymodel,self);

            nFile = self.model.getNFile();
            self.trialControllerArray = cell(1,nFile);
            % Listento MATLAB root object for changing of current figure
            self.rootListener = listener(groot,'CurrentFigure','PostSet',@self.selectTrial_Callback);
        end
        
        % function setLoadMovieOption(self,loadMovieOption)
        %     self.model.loadMovieOption = loadMovieOption;
        % end
        
        function addFilePath_Callback(self,filePath)
            self.model.addFilePath(filePath);
            self.trialControllerArray{end+1} = [];
        end
        
        function loadRangeGroup_Callback(self,src,evnt)
            button = evnt.NewValue;
            tag = button.Tag;
            if strcmp(tag,'loadrange_radiobutton_2')
                self.view.toggleLoadRangeText('on');
                loadRange = self.view.getLoadRangeFromText();
                self.model.loadMovieOption.zrange = loadRange;
            else
                self.view.toggleLoadRangeText('off');
                self.model.loadMovieOption.zrange = 'all';
            end
        end
        
        function loadRangeText_Callback(self,src,evnt)
            startText = self.view.guiHandles.loadRangeStartText;
            endText = self.view.guiHandles.loadRangeEndText;
            startStr = startText.String;
            endStr = endText.String;
            startFrameNum = round(str2num(startStr));
            endFrameNum = round(str2num(endStr));
            
            switch src.Tag
              case 'loadrange_start_text'
                if startFrameNum < 1
                    startFramenNum = 1;
                end
                if startFrameNum > endFrameNum
                    startFrameNum = endFrameNum;
                end
                self.model.loadMovieOption.zrange = ...
                    [startFrameNum,endFrameNum];
                set(src,'String',num2str(startFrameNum));
              case 'loadrange_end_text'
                if endFrameNum < startFrameNum
                    endFrameNum = startFrameNum;
                end
                self.model.loadMovieOption.zrange = ...
                    [startFrameNum,endFrameNum];
                set(src,'String',num2str(endFrameNum));
            end
        end
        
        function loadStepText_Callback(self,src,evnt)
            stepStr = src.String;
            nFramePerStep = str2num(stepStr);
            self.model.loadMovieOption.nFramePerStep = nFramePerStep;
        end

        function selectTrial(self,ind)
            self.model.currentTrialInd = ind;
            % if isempty(ind)
            %     disp('Unselect trial');
            % else 
            %     disp(sprintf('trial #%d selected',ind));
            % end
        end
        
        function selectTrial_Callback(self,src,evnt)
        % disp('selectTrial_Callback called')
            fig = evnt.AffectedObject.(src.Name);
            if ~isempty(fig)
                tag = fig.Tag;
                indStr =  regexp(tag,'trial_(\d+)*','tokens');
                if ~isempty(indStr)
                    ind = str2num(indStr{1}{1});
                    self.selectTrial(ind);
                end
            end
        end

        function trialDeleted_Callback(self,src,evnt)
            ind = [];
            self.selectTrial(ind);
            self.view.raiseMainWindow();
        end
        
        function fileListBox_Callback(self,src,evnt)
            fig = src.Parent;
            if strcmp(fig.SelectionType,'open')
                ind = src.Value;
                if self.isTrialOpened(ind)
                    self.raiseTrialView(ind);
                else
                    self.openTrial(ind);
                end
            end
        end
        
        function res = isTrialOpened(self,ind)
            trialController = self.trialControllerArray{ind};
            trial = self.model.getTrialByInd(ind);
            res = false;
            if ~isempty(trialController) && ~isempty(trial)
                if isvalid(trialController) && ...
                        isvalid(trialController)
                    res = true;
                end
            end
        end
        
        function openTrial(self,ind)
            self.model.loadTrial(ind);
            trial = self.model.getTrialByInd(ind);
            addlistener(trial,'trialDeleted',@self.trialDeleted_Callback);
            trialController = TrialController(trial);
            % trialController.addMap('anatomy');
            trialController.setSyncTimeTrace(true);
            tagPrefix = sprintf('trial_%d',ind);
            trialController.setFigTagPrefix(tagPrefix);
            self.trialControllerArray{ind} = trialController;
            trialController.raiseView();
        end
        
        function raiseTrialView(self,ind)
            trialController = self.trialControllerArray{ind};
            trialController.raiseView();
        end
        
        function mainFigClosed_Callback(self,src,evnt)
            self.view.deleteFigures();
            delete(self.view);
            delete(self.model)
            delete(self)
        end
        
        
        function delete(self)
            if isvalid(self.view)
                self.view.deleteFigures();
                delete(self.view)
            end
        end
    end
end
