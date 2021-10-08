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
            set(self.guiHandles.contrastMinSlider,'Callback',...
                              @(s,e)self.controller.contrastSlider_Callback(s,e));
            set(self.guiHandles.contrastMaxSlider,'Callback',...
                              @(s,e)self.controller.contrastSlider_Callback(s,e));

        end
        
        function selectAndDisplayMap(self,src,evnt)
            self.displayCurrentMap();
        end
        
        function displayCurrentMap(self)
            map = self.model.getCurrentMap();
            self.plotMap(map);
            self.displayMeta(map.meta);
            self.controller.updateContrastForCurrentMap();
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

        % Methods for changing contrast
        function changeMapContrast(self,contrastLim)
        % Usage: myview.changeMapContrast(contrastLim), contrastLim
        % is a 1x2 array [cmin cmax]
            caxis(self.guiHandles.mapAxes,contrastLim);
        end


        function setDataLimAndContrastLim(self,dataLim,contrastLim)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                cs = contrastSliderArr(end+1-k);
                set(cs,'Min',dataLim(1),'Max',dataLim(2),...
                       'Value',contrastLim(k));
            end
        end

        function dataLim = getContrastSliderDataLim(self)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            dataLim(1) = contrastSliderArr(1).Min;
            dataLim(2) = contrastSliderArr(1).Max;
        end

        function setContrastSliderDataLim(self,dataLim)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastSliderArr(end+1-k).Min = dataLim(1);
                contrastSliderArr(end+1-k).Max = dataLim(2);
            end
        end

        function contrastLim = getContrastLim(self)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastLim(k) = contrastSliderArr(end+1-k).Value;
            end
        end

        function setContrastLim(self,contrastLim)
            contrastSliderArr= ...
                self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastSliderArr(end+1-k).Value = contrastLim(k);
            end
        end
    end
    
end
