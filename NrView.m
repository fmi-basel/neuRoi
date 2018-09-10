classdef NrView < handle
    properties
        model
        controller
        guiHandles
    end
    
    methods
        function self = NrView(mymodel,mycontroller)
            self.model = mymodel;
            self.controller = mycontroller;
            self.guiHandles = neuRoiGui();
            
            self.updateFileListBox();
            self.displayLoadMovieOption();
            
            self.listenToModel();
            self.assignCallbacks();
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.fileListBox,'Callback',...
                @(s,e)self.controller.fileListBox_Callback(s,e));
            set(self.guiHandles.mainFig,'CloseRequestFcn',...
                @(s,e)self.controller.mainFigClosed_Callback(s,e));
            set(self.guiHandles.loadRangeGroup,'SelectionChangedFcn',...
                @(s,e)self.controller.loadRangeGroup_Callback(s,e));
            set(self.guiHandles.loadStepText,'Callback',...
                @(s,e)self.controller.loadStepText_Callback(s,e));
        end
        
        function listenToModel(self)
            addlistener(self.model,'filePathArray','PostSet',@self.updateFileListBox);
        end
        
        function updateFileListBox(self)
            filePathArray = self.model.filePathArray;
            fileNameArray = {};
            for k = 1:length(filePathArray)
                filePath = filePathArray{k};
                [~,fileNameArray{k},~] = fileparts(filePath);
            end
            set(self.guiHandles.fileListBox,'String',fileNameArray);
        end
        
        function displayLoadMovieOption(self)
            option = self.model.loadMovieOption;
            nFramePerStep = option.nFramePerStep;
            self.guiHandles.loadStepText.String = num2str(nFramePerStep);
            zrange = option.zrange;
            if isnumeric(zrange)
                self.guiHandles.loadRangeButton2.Value = 1;
                self.toggleLoadRangeText('on');
                self.setLoadRangeText(zrange);
            elseif strcmp(zrange,'all')
                self.guiHandles.loadRangeButton1.Value = 1;
                self.toggleLoadRangeText('off');
            else
                error('Cannot display load movie range!')
            end
        end
        
        function toggleLoadRangeText(self,state)
            if strcmp(state,'on') || strcmp(state,'off')
                set(self.guiHandles.loadRangeStartText,'Enable',state);
                set(self.guiHandles.loadRangeEndText,'Enable',state);
            else
                error('The state should be ''on'' or ''off''');
            end
        end
        
        function setLoadRangeText(self,zrange)
            set(self.guiHandles.loadRangeStartText,'String', ...
                              num2str(zrange(1)));
            set(self.guiHandles.loadRangeEndText,'String', ...
                              num2str(zrange(2)));
        end
        
        function zrange = getLoadRangeFromText(self);
            zrange(1) = str2num(self.guiHandles.loadRangeStartText.String);
            zrange(2) = str2num(self.guiHandles.loadRangeEndText.String);
        end
        
        function deleteFigures(self)
            mainFig = self.guiHandles.mainFig;
            delete(mainFig);
        end
        
        function raiseMainWindow(self)
            mainFig = self.guiHandles.mainFig;
            figure(mainFig)
        end

    end
end
