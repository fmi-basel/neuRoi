classdef TrialStackView < handle
    properties
        model
        controller
        guiHandles
        mapColorMap
    end

    methods
        function self = TrialStackView(mymodel,mycontroller)
            self.model = mymodel;
            self.controller = mycontroller;
            self.guiHandles = trialStack.trialStackGui(self.model.mapSize);
            [neuRoiDir, ~, ~]= fileparts(mfilename('fullpath'));
            
            % Load customized color map
            cmapPath = fullfile(neuRoiDir, 'colormap', ...
                                'clut2b.mat');
            try
                foo = load(cmapPath);
                self.mapColorMap = foo.clut2b;
            catch ME
                self.mapColorMap = 'default';
            end

            self.listenToModel();
            self.assignCallbacks();
        end
        
        function listenToModel(self)
            addlistener(self.model,'currentTrialIdx','PostSet',@self.selectAndDisplayMap);
            addlistener(self.model,'mapType','PostSet',@self.selectAndDisplayMap);
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.mainFig,'WindowKeyPressFcn',...
                              @(s,e)self.controller.keyPressCallback(s,e));
        end
        
        function selectAndDisplayMap(self,src,evnt)
            self.displayCurrentMap();
        end
        
        function displayCurrentMap(self)
            map = self.model.getCurrentMap();
            self.plotMap(map);
            self.displayMeta(map.meta);
        end
        
        function displayMeta(self,meta)
            metaStr = helper.convertOptionToString(meta);
            set(self.guiHandles.metaText,'String',metaStr);
        end
        
        function plotMap(self,map)
            mapAxes = self.guiHandles.mapAxes;
            mapImage = self.guiHandles.mapImage;
            set(mapImage,'CData',map.data);
            cmap = self.mapColorMap;
            switch map.type
              case 'anatomy'
                colormap(mapAxes,gray);
              case 'response'
                colormap(mapAxes,cmap);
              otherwise
                colormap(mapAxes,'default');
            end
        end
    end
    
end
