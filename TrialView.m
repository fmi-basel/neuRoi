classdef TrialView < handle
    properties
        model
        controller
        guiHandles
    end
    
    methods
        function self = TrialView(mymodel,mycontroller)
            self.model = mymodel;
            self.controller = mycontroller;
            
            mapSize = self.model.getMapSize();
            self.guiHandles = trialGui(mapSize);
            
            self.listenToModel();
            self.assignCallbacks();
        end
        
        function listenToModel(self)
            addlistener(self.model,'currentMapInd','PostSet',@self.selectAndDisplayMap);
            addlistener(self.model,'mapArrayLengthChanged',@self.toggleMapButtonValidity);
            addlistener(self.model,'mapUpdated',@self.updateMapDisplay);
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.mapButtonGroup,'SelectionChangedFcn', ...
               @(s,e)self.controller.mapButtonSelected_Callback(s,e));
            set(self.guiHandles.mainFig,'CloseRequestFcn',...
               @(s,e)self.controller.mainFigClosed_Callback(s,e));
        end
        
        % Methods for displaying maps
        function selectAndDisplayMap(self,src,evnt)
            obj = evnt.AffectedObject;
            ind = obj.currentMapInd;
            map = obj.getMapByInd(ind);
            
            self.selectMapButton(ind);
            self.displayMap(map);
        end
        
        function toggleMapButtonValidity(self,src,evnt)
            nActiveButton = src.getMapArrayLength();
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            for k=1:length(mapButtonArray)
                mb = mapButtonArray(end+1-k);
                if k <= nActiveButton
                    mb.Enable = 'on';
                else
                    mb.Enable = 'off';
                end
            end
        end

        function updateMapDisplay(self,src,evnt)
            currInd = src.currentMapInd;
            updatedInd = evnt.ind;
            if currInd == updatedInd
                map = self.model.getMapByInd(currInd);
                self.displayMap(map);
            end
        end
        
        function selectMapButton(self,ind)
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            mapButtonGroup.SelectedObject = mapButtonArray(end+1-ind);
        end
            
        function displayMap(self,map)
            self.showMapOption(map);
            self.plotMap(map);
        end
        
        function showMapOption(self,map)
            optionStr = TrialView.convertOptionToString(map.option);
            self.guiHandles.mapOptionText.String = optionStr;
        end
        
        function plotMap(self,map)
            mapAxes = self.guiHandles.mapAxes;
            mapImage = self.guiHandles.mapImage;
            switch map.type
              case 'anatomy'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,gray);
              case 'response'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,'default');
              case 'responseMax'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,'default');
              case 'localCorrelation'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,'default');
              otherwise
                set(mapImage,'CData',map.data);
                colormap(mapAxes,'default');
            end
        end
        
        function setFigTagPrefix(self,prefix)
            mainFig = self.guiHandles.mainFig;
            traceFig = self.guiHandles.traceFig;
            mainFigTag = mainFig.Tag;
            set(mainFig,'Tag',[prefix '_' mainFigTag])
            traceFigTag = traceFig.Tag;
            set(traceFig,'Tag',[prefix '_' traceFigTag])
        end

        function raiseFigures(self)
            mainFig = self.guiHandles.mainFig;
            % traceFig = self.guiHandles.traceFig;
            figure(mainFig)
        end
        
        function deleteFigures(self)
            mainFig = self.guiHandles.mainFig;
            traceFig = self.guiHandles.traceFig;
            delete(mainFig);
            delete(traceFig);
        end
    end
    
    methods (Static)
        function optionStr = convertOptionToString(option)
            nameArray = fieldnames(option);
            stringArray = {};
            for i = 1:length(nameArray)
                name = nameArray{i};
                value = option.(name);
                stringArray{i} = sprintf('%s: %s',name,mat2str(value));
            end
            optionStr = [sprintf(['%s; '],stringArray{1:end-1}), ...
                         stringArray{end}];
                
        end
    end
end
