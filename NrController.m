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
        
        function loadFileTypeGroup_Callback(self,src,evnt)
            button = evnt.NewValue;
            tag = button.Tag;
            if strcmp(tag,'loadfiletype_radio_1')
                self.model.loadFileType = 'binned';
            else
                self.model.loadFileType = 'raw';
            end
        end
        
        
        function planeNumText_Callback(self,src,evnt)
            planeNumStr = src.String;
            planeNum = str2num(planeNumStr);
            self.model.planeNum = planeNum;
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
            % slidingWindowSize = round(slidingWindowSize);
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
                idx = src.Value;
                % TODO specify load fileType in GUI
                self.openTrialFromList(idx);
            end
        end
        
        function openTrialFromList(self,fileIdx)
            fileType = self.model.loadFileType;
            planeNum = self.model.planeNum;
            trial = self.model.loadTrialFromList(fileIdx,fileType,planeNum);
            self.openTrialContrl(trial);
        end
        
        function openAdditionalTrial(self,filePath,varargin)
            trial = self.model.loadAdditionalTrial(filePath,varargin{:});
            self.openTrialContrl(trial);
        end
        
        function openTrialContrl(self,trial)
            addlistener(trial,'trialDeleted',@self.trialDeleted_Callback);
            trialContrl = TrialController(trial);
            % trialContrl.setSyncTimeTrace(true);
            self.trialContrlArray(end+1) = trialContrl;
            trialContrl.raiseView();
            
            mapsAfterLoading = self.model.mapsAfterLoading;
            if length(mapsAfterLoading)
                for k = 1:length(mapsAfterLoading)
                    mapType = mapsAfterLoading{k};
                    self.model.addMapCurrTrial(mapType);
                end
            end
            
            if self.model.loadTemplateRoi
                roiFilePath = self.model.roiTemplateFilePath;
                trial.loadRoiArray(roiFilePath,'replace')
            end
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
            % startFrameNum = round(str2num(startStr));
            % endFrameNum = round(str2num(endStr));
            startNum = str2num(startStr);
            endNum = str2num(endStr);
            switch src.Tag
              case startText.Tag
                set(src,'String',num2str(startNum));
              case endText.Tag
                set(src,'String',num2str(endNum));
            end
            wdw = [startNum endNum];
        end

    end
    
end
