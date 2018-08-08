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
            self.listenToModel();
            self.assignCallbacks();
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.fileListBox,'Callback',...
                @(s,e)self.controller.fileListBox_Callback(s,e));
            set(self.guiHandles.mainFig,'CloseRequestFcn',...
                @(s,e)self.controller.mainFigClosed_Callback(s,e));
        end
        
        function listenToModel(self)
            addlistener(self.model,'filePathArray','PostSet',@self.updateFileListBox);
        end
        
        function updateFileListBox(self)
            filePathArray = self.model.filePathArray;
            set(self.guiHandles.fileListBox,'String',filePathArray);
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

