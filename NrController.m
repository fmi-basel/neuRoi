classdef NrController < handle
    properties
        model
        view
        trialContrlArray
        rootListener
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(mymodel,self);

            % nFile = self.model.getNFile();
            self.trialContrlArray = TrialController.empty;
            % Listen to MATLAB root object for changing of current figure
            self.rootListener = listener(groot,'CurrentFigure','PostSet',@self.selectTrial_Callback);
        end
        
        % function setLoadMovieOption(self,loadMovieOption)
        %     self.model.loadMovieOption = loadMovieOption;
        % end
        
        function addFilePath_Callback(self,filePath)
            self.model.addFilePath(filePath);
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
            wdw = NrController.setCorrectWindow(startText,endText,src);
            self.model.loadMovieOption.zrange = wdw;
        
        end
        
        function loadStepText_Callback(self,src,evnt)
            stepStr = src.String;
            nFramePerStep = str2num(stepStr);
            self.model.loadMovieOption.nFramePerStep = nFramePerStep;
        end
        
        % Callbacks for dF/F map parameters
        function resIntensityOffset_Callback(self,src,evnt)
            intensityOffsetStr = src.String;
            intensityOffset = str2num(intensityOffsetStr);
            self.model.responseOption.offset= intensityOffset;
        end

        function resFZero_Callback(self,src,evnt)
            startText = self.view.guiHandles.resFZeroStartText;
            endText = self.view.guiHandles.resFZeroEndText;
            wdw = NrController.setWindow(startText,endText,src);
            self.model.responseOption.fZeroWindow = wdw;
        end
        
        function responseWindow_Callback(self,src,evnt)
            startText = self.view.guiHandles.responseStartText;
            endText = self.view.guiHandles.responseEndText;
            wdw = NrController.setWindow(startText,endText,src);
            self.model.responseOption.responseWindow = wdw;
        end
        
        function mapType = getMapTypeFromButton(self,hbutton,buttonType)
            matched = regexp(hbutton.Tag,[buttonType '_(\w+)'], ...
                             'tokens'); %XXXX
            if length(matched)
                mapType = matched{1}{1};
            else
                mapType = '';
            end
        end
        
        function addMapButton_Callback(self,src,evnt)
            mapType = self.getMapTypeFromButton(src, ...
                                                'addMapButton');
            self.model.addMapCurrTrial(mapType)
        end
        
        function updateMapButton_Callback(self,src,evnt)
            mapType = self.getMapTypeFromButton(src, ...
                                                'updateMapButton');
            self.model.updateMapCurrTrial(mapType)
        end
        
        % Callbacks for max dF/F map parameters
        function rmaxIntensityOffset_Callback(self,src,evnt)
            intensityOffsetStr = src.String;
            intensityOffset = str2num(intensityOffsetStr);
            self.model.responseMaxOption.offset= intensityOffset;
        end

        function rmaxFZero_Callback(self,src,evnt)
            startText = self.view.guiHandles.rmaxFZeroStartText;
            endText = self.view.guiHandles.rmaxFZeroEndText;
            wdw = NrController.setWindow(startText,endText,src);
            self.model.responseMaxOption.fZeroWindow = wdw;
        end
        
        function rmaxSlidingWindow_Callback(self,src,evnt)
            sstr = src.String;
            slidingWindowSize = str2num(sstr);
            if slidingWindowSize <=0
                errorStruct.message(['Sliding window size should be ' ...
                                    'a positive integer']);
                self.view.displayError(errorStruct);
                return
            end
            slidingWindowSize = round(slidingWindowSize);
            self.model.responseMaxOption.slidingWindowSize = slidingWindowSize;
            src.String = num2str(slidingWindowSize);
        end
        
        function selectTrial_Callback(self,src,evnt)
            fig = evnt.AffectedObject.(src.Name);
            if ~isempty(fig)
                tag = fig.Tag;
                trialTag = regexp(tag,'trial_([a-zA-Z0-9]+)_','tokens');
                if ~isempty(trialTag)
                    self.model.selectTrial(trialTag{1}{1});
                end
            end
        end

        function trialDeleted_Callback(self,src,evnt)
            trialTag = src.tag;
            idx = self.model.getTrialIdx(trialTag);
            self.model.selectTrial([]);
            self.model.trialArray(idx) = [];
            self.trialContrlArray(idx) = [];
        end
        
        function fileListBox_Callback(self,src,evnt)
            fig = src.Parent;
            if strcmp(fig.SelectionType,'open')
                ind = src.Value;
                if self.isTrialOpened(ind)
                    %self.raiseTrialView(ind);
                    % TODO raise view by tag
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
        
        function openTrial(self,fileIdx,fileType,varargin)
            trial = self.model.loadTrial(fileIdx,fileType,varargin{:});
            addlistener(trial,'trialDeleted',@self.trialDeleted_Callback);
            trialContrl = TrialController(trial);
            trialContrl.setSyncTimeTrace(true);
            self.trialContrlArray(end+1) = trialContrl;
            trialContrl.raiseView();
        end
        
        function raiseTrialView(self,ind)
            trialController = self.trialControllerArray{ind};
            trialController.raiseView();
        end           
        
        function mainFigClosed_Callback(self,src,evnt)
            for i=1:length(self.trialContrlArray)
                trialContrl = self.trialContrlArray(i);
                trialContrl.mainFigClosed_Callback(1,1);
            end
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
    
    methods (Static)
        function wdw = setCorrectWindow(startText,endText,src)
            % TODO when window is not integer 
            startStr = startText.String;
            endStr = endText.String;
            startFrameNum = round(str2num(startStr));
            endFrameNum = round(str2num(endStr));
            
            switch src.Tag
              case startText.Tag
                if startFrameNum < 1
                    startFramenNum = 1;
                end
                if startFrameNum > endFrameNum
                    startFrameNum = endFrameNum;
                end
                set(src,'String',num2str(startFrameNum));
              case endText.Tag
                if endFrameNum < startFrameNum
                    endFrameNum = startFrameNum;
                end
                set(src,'String',num2str(endFrameNum));
            end
            wdw = [startFrameNum endFrameNum];
        end
        
        function wdw = setWindow(startText,endText,src)
            % TODO when window is not integer
            startStr = startText.String;
            endStr = endText.String;
            startFrameNum = round(str2num(startStr));
            endFrameNum = round(str2num(endStr));
            switch src.Tag
              case startText.Tag
                set(src,'String',num2str(startFrameNum));
              case endText.Tag
                set(src,'String',num2str(endFrameNum));
            end
            wdw = [startFrameNum endFrameNum];
        end

    end
    
end
