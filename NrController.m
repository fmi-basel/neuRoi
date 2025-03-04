classdef NrController < handle
    properties
        model
        view
        trialCtrlArray
        rootListener
        importGui
        stackCtrl
    end
    
    methods
        function self = NrController(mymodel)
            self.model = mymodel;
            self.view = NrView(mymodel,self);

            % nFile = self.model.getNFile();
            self.trialCtrlArray = trialMvc.TrialController.empty;
            % Listen to MATLAB root object for changing of current figure
            self.rootListener = listener(groot,'CurrentFigure','PostSet',@self.selectTrial_Callback);
        end
        
        % function setLoadMovieOption(self,loadMovieOption)
        %     self.model.loadMovieOption = loadMovieOption;
        % end
        
                
        function loadExperiment(self,filePath)
            foo = load(filePath);
            fld = fieldnames(foo);
            fld = fld{1};
            if ismember(fld,{'myexp','self'})
                model = foo.(fld);
                model.trialArray = trialMvc.TrialModel.empty;
                self.model = model;
                self.view.model = self.model;
                self.model.LoadCalculatedTransformation();
                self.view.refreshView();
            else
                error('Invalid experiment file!')
            end
        end
        
        function loadExperiment_Callback(self,src,evnt)
            [fileName,fileDir] = uigetfile('*.mat',['Open ' ...
                                'Experiment']);
            if fileName
                filePath = fullfile(fileDir,fileName);
                self.loadExperiment(filePath);
            end
        end
        
        function newExperiment(self)
            self.model = NrModel();
            self.view.model = self.model;
            self.view.refreshView();
        end
        
        function newExperiment_Callback(self,src,evnt)
            self.newExperiment()
        end
        
        function importRawData_Callback(self,src,evnt)
            self.importGui = gui.importRawDataGui(self.model);
        end
        
        function saveExperiment_Callback(self,src,evnt)
            filePath = self.model.getDefaultFile('experiment');
            [fileName,fileDir] = uiputfile(filePath,'Save experiment');
            if fileName
                filePath = fullfile(fileDir,fileName);
                self.model.saveExperiment(filePath);
            end
        end

        function expInfo_Callback(self,src,evnt)
            tag = src.Tag;
            propName = regexp(tag,'Edit')
            val = str2num(src.String);
            self.model.expInfo.(propName) = val;
        end
        
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
%             if mapType=="SetupCAnatomy"
%                 mapType="anatomy"
%             end 
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
            self.trialCtrlArray(idx) = [];
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
            trialContrl = trialMvc.TrialController(trial);
            self.trialCtrlArray(end+1) = trialContrl;
            trialContrl.raiseView();
            
            if isempty(self.model.loadMapFromFile) || ~self.model.loadMapFromFile %ignores mapsAfterLoading if true
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
            else
                %TempMapFolder = fullfile(self.model.precalculatedMapDir,trial.name);
                %TempMapFolder = 'C:/Data/eckhjan/test/SetupC/TestExperiment/SetupC/1';
                TempMapFolder = fullfile(self.model.resultDir,'SetupC',self.model.getPlaneString(self.model.planeNum),trial.name);
                if exist("TempMapFolder")==7
                    error(strcat("Precalculated Map Folder",string(TempMapFolder)," doesn't exist"));
                else
                    self.model.LoadMapsFromFileCurrTrial(TempMapFolder);
                    trialContrl.view.SetupParaAfterMapsLoaded(trialContrl.model.loadedMapsize);
                end
            end
        end
        
        function trialCtrl = getCurrentTrialCtrl(self)
            trialCtrl = self.trialCtrlArray(self.model.currentTrialIdx);
        end
        
        function raiseTrialView(self,ind)
            trialController = self.trialControllerArray{ind};
            trialController.raiseView();
        end
                
        function mainFigClosed_Callback(self,src,evnt)
            for i=1:length(self.trialCtrlArray)
                trialContrl = self.trialCtrlArray(i);
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

        % Callbacks for SetupC parameters

        function rmaxSlidingWindowSetupCText_Callback(self,src,evnt)
            rmaxSlidingWindowStr = src.String;
            rmaxSlidingWindow = str2num(rmaxSlidingWindowStr);
            self.model.SetupCMaxResponseOption.slidingWindowSize= rmaxSlidingWindow;
        
        end

        function SetupCPercentileText_Callback(self,src,evnt)
            SetupCPercentileStr = src.String;
            SetupCPercentile = str2num(SetupCPercentileStr);
            self.model.SetupCResponseOption.lowerPercentile= SetupCPercentile;
            self.model.SetupCMaxResponseOption.lowerPercentile= SetupCPercentile;
        end

       function SetupCSkippingText_Callback(self,src,evnt)
        SkippingStr = src.String;
        Skipping = str2num(SkippingStr);
        self.model.SetupCResponseOption.skipping= Skipping;
        self.model.SetupCCorrOption.skipping= Skipping;
        self.model.SetupCMaxResponseOption.skipping= Skipping;
        self.model.SetupCAnatomyOption.skipping= Skipping;
       end

        function SetupCoffsetText_Callback(self,src,evnt)
        offsetStr = src.String;
        offset = str2num(offsetStr);
        self.model.SetupCAnatomyOption.offset= offset;
        self.model.SetupCResponseOption.offset= offset;
        self.model.SetupCMaxResponseOption.offset= offset;
        end

        function SetupCExtractTracesDfoverfButton_Callback(self,src,evnt)
            self.model.SetupCExtractTracesDfoverf();
        
        end

        % Callbacks for BUnwaprJ
        function BUnwarpJReferencetrial_Callback(self,src,evnt)
            self.model.referenceTrialIdx=src.Value;
        end

        function BUnwarpJCalculateButton_Callback(self,src,evnt)
            nameOK = self.CheckBunwarpJName();
            if nameOK
                self.model.registerTrials();
                self.view.refreshView();
            end
        end
        
        function NameOK=CheckBunwarpJName(self)
            if isempty(self.model.transformationName)
                msgbox("Transformationname is empty. Please enter a valid name","modal");
                NameOK= false;
                return
            else
                files= dir(fullfile(self.model.resultDir,"BUnwarpJ"));
                dirFlags = [files.isdir];
                subFolders = files(dirFlags);
                subFolderNames = {subFolders(3:end).name};
                DoesTransforExist = ismember(subFolderNames,self.model.transformationName);
                if sum(DoesTransforExist)==0
                    NameOK=true;
                    return
                else
                    opts.Interpreter = 'tex';
                    opts.Default = 'No';
                    answer = questdlg('Transformationname already exist. Do you want to overwrite the folder?',...
                             'Overwrite transformation', ...
                             'Yes','No', opts);
                    if strcmp(answer, 'Yes')
                        NameOK = true;
                    else
                        NameOK = false;
                    end
                return
                end
            end
        end

        function BUnwarpJPara_Callback(self,src,evnt)
            TempParameter=thirdPartyTools.structdlg.StructDlg(self.model.BUnwarpJParameter,'BUnwarpJ parameter');
            self.model.BUnwarpJParameter=TempParameter;
        end

        function BUnwarpJCLAHEPara_Callback(self,src,evnt)
            TempParameter=thirdPartyTools.structdlg.StructDlg(self.model.CLAHEParameter,'CLAHE parameter');
            self.model.CLAHEParameter=TempParameter;
        end

        function BUnwarpJUseSIFT_Callback(self,src,evnt)
            self.model.transformParam.useSift = src.Value;
        end

        function BUnwarpJSIFTPara_Callback(self,src,evnt)
            TempParameter=thirdPartyTools.structdlg.StructDlg(self.model.SIFTParameter,'SIFT parameter');
            self.model.SIFTParameter=TempParameter;
        end

        function BUnwarpJInspectTrialsButton_Callback(self,src,evnt)
            self.model.inspectStack();
            self.stackCtrl = trialStack.TrialStackController(self.model.stackModel);
        end

        function BUnwarpJTransformationName_Callback(self,src,evnt)
            self.model.transformationName=src.String;
        end
        
        function BUnwarpJCalculatedTransformations_Callback(self,src,evnt)
            self.model.calculatedTransformationsIdx=src.Value;
            self.model.UpdateTransformationTooltipValue();
            self.view.updateTransformationTooltip();
        end
        
        function BUnwarpJNormTypeGroup_Callback(self,src,evnt)
            button = evnt.NewValue;
            tag = button.Tag;
            if strcmp(tag,'Norm_HistoEqu_radiobutton')
                self.model.transformParam.normParam.useHistoEqual = true;
                self.model.transformParam.normParam.useClahe = false;
            elseif strcmp(tag,'Norm_CLAHE_radiobutton')
                self.model.transformParam.normParam.useHistoEqual = false;
                self.model.transformParam.normParam.useClahe = true;
            else
                self.model.transformParam.normParam.useHistoEqual = false;
                self.model.transformParam.normParam.useClahe = false;
            end
        end

        function RoiIdentfierText_Callback(self,src,evnt)
            self.model.roiFileIdentifier=src.String;
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
