classdef NrController < handle
    properties
        model
        view
    end
       
    properties (SetObservable)
        currentMapInd
        timeTraceState
        roiDisplayState
    end
    
    methods
        function self = NrController(mymodel)
            self.timeTraceState = 'dfOverF';
            self.roiDisplayState = true;

            self.model = mymodel;
            self.view = NrView(self,self.model.fileBaseName,self.model.getMapSize());
            
            mapArrayLen = self.model.getMapArrayLength();
            self.view.toggleMapButtonValidity(mapArrayLen);
            if mapArrayLen
                self.selectMap(1);
            end
        end
        
        function addMap(self,type,varargin)
            nMapButton = self.view.getNMapButton();
            mapArrayLen = self.model.getMapArrayLength();
            if mapArrayLen >= nMapButton
                error('Cannot add more than %d maps',nMapButton);
            end
            self.model.calculateAndAddNewMap(type,varargin{:});
            self.view.toggleMapButtonValidity(mapArrayLen+1);
            self.selectMapWithMapButtonPressed(mapArrayLen+1);
        end
        
        function selectMapWithMapButtonPressed(self,ind);
            self.selectMap(ind);
            self.view.selectMapButton(ind);
        end
            
        function selectMap(self,ind)
            disp(sprintf('selectMap: map #%d selected',ind));
            map = self.model.getMapByInd(ind);
            self.view.displayMap(map);
            self.view.enableMapOptionPanel(map);
            
            % Update contrast control
            self.updateContrastForSelectedMap(ind,map);
        end
        
        function updateContrastForSelectedMap(self,ind,map)
            dataLim = minMax(map.data);
            dataLim(2) = dataLim(2) + eps;
            self.view.setSliderDataLim(dataLim);
            savedContrastLim = ...
                self.view.getSavedContrastLim(ind);
            if ~isempty(savedContrastLim)
                % Calculate new contrast limit
                ss = rangeIntersect(dataLim,savedContrastLim);
                if ~isempty(ss)
                    contrastLim = ss;
                else
                    contrastLim = dataLim;
                end
            else
                contrastLim = dataLim;
            end
            self.view.setContrastLim(contrastLim);
            self.view.saveContrastLim(ind,contrastLim);
            self.view.changeMapContrast(contrastLim);
        end

        
        function deleteCurrentMap(self)
            ind = self.view.getCurrentMapInd();
            mapArrayLen = self.model.getMapArrayLength();
            if ind > mapArrayLen
                error('Index exceeded total number of maps!');
            end
            self.model.deleteMap(ind);
            self.view.deleteSavedContrastLim(ind);
            if ind == mapArrayLen
                newInd = mapArrayLen-1;
            else
                newInd = ind;
            end
            self.selectMapWithMapButtonPressed(newInd);
            self.view.toggleMapButtonValidity(mapArrayLen-1);
        end
        
        function updateMap(self,ind,option)
            self.model.updateMap(ind,option);
            self.selectMapWithMapButtonPressed(ind);
        end
        
        function changeContrastLim(self,contrastSliderInd)
        % Method to change contrast of map image
            contrastLim = self.view.getContrastLim();
            dataLim = self.view.getSliderDataLim();
            % Check whether contrastLim is valid (min < max), otherwise set the
            % other slider to a valid value based on the new value of
            % the changed slider;
            if contrastLim(1) >= contrastLim(2)
                sn = 10000*eps; % a small number
                switch contrastSliderInd
                  case 1
                    if contrastLim(1) >= dataLim(2)
                        contrastLim(1) = dataLim(2)-sn;
                    end
                    contrastLim(2) = contrastLim(1)+sn;
                  case 2
                    if contrastLim(2) <= dataLim(1)
                        contrastLim(2) = dataLim(1)+sn;
                    end
                    contrastLim(1) = contrastLim(2)-sn;
                  otherwise
                    error('contrastSliderInd should be 1 or 2 ');
                end
                self.view.setContrastLim(contrastLim);
            end
            mapInd = self.view.getCurrentMapInd();
            self.view.saveContrastLim(mapInd,contrastLim);
            self.view.changeMapContrast(contrastLim);
        end
        
        % Change ROI display state
        function toggleRoiDisplayState(self)
            self.roiDisplayState = ~self.roiDisplayState;
        end
        
        % ROI funcitons
        function addRoiInteract(self)
            if ~self.roiDisplayState
                self.roiDisplayState = true;
            end
            rawRoi = imfreehand;
            %TODO important, deal with roi cancelled by Esc!!
            if ~isempty(rawRoi)
                position = rawRoi.getPosition();
                delete(rawRoi)
                imageInfo = getImageSizeInfo(self.view.guiHandles.mapImage);
                if ~isempty(position)
                    freshRoi = RoiFreehand(0,position,imageInfo);
                    roiPatch = self.addRoi(freshRoi);
                    % Set the new ROI as the selected ROI
                    self.selectSingleRoi(roiPatch);
                end
            end
        end

        function roiPatch = addRoi(self,roi)
            if isvalid(roi) && isa(roi,'RoiFreehand')
                % TODO check if image info matches
                self.model.addRoi(roi);
                roiPatch = self.view.addRoiPatch(roi);
            else
                warning('Invalid ROI!')
            end
        end

        function selectSingleRoi(self,varargin)
            if nargin == 1
                selectedObj = gco; % get(gco,'Parent');
            elseif nargin == 2
                selectedObj = varargin{1};
            else
                error('Wrong usage!')
            end
            
            tag = get(selectedObj,'Tag');
            if and(~isempty(selectedObj),strfind(tag,'roi_'))
                self.view.selectSingleRoiPatch(selectedObj);
                slRoi = getappdata(selectedObj,'roiHandle');
                self.model.selectSingleRoi(slRoi);
                
                trace = self.model.selectedTraceArray{end};
                self.view.holdTraceAxes('off');
                self.view.plotTimeTrace(trace,slRoi.id);
            else
                cla(self.view.guiHandles.traceAxes);
                self.view.holdTraceAxes('off');
                self.view.unselectAllRoiPatch();
                self.model.unselectAllRoi();
            end
        end
        
        function selectMultRoi_Callback(self)
            selectedObj = gco; % get(gco,'Parent');
            tag = get(selectedObj,'Tag');

            if and(~isempty(selectedObj),strfind(tag,'roi_'))
                if strcmp(selectedObj.Selected,'off')
                    self.selectRoi(selectedObj)
                else
                    self.unselectRoi(selectedObj)
                end
            end
        end
                    
        function selectRoi(self,roiPatch)
            self.view.selectRoiPatch(roiPatch);
            slRoi = getappdata(roiPatch,'roiHandle');
            self.model.selectRoi(slRoi);
            
            self.view.holdTraceAxes('on');
            trace = self.model.selectedTraceArray{end};
            self.view.plotTimeTrace(trace,slRoi.id);
        end
        
        function unselectRoi(self,roiPatch)
            tag = get(roiPatch,'Tag');
            roiId = regexp(tag,'\d{4}','match');
            roiId = str2num(roiId{:})
            self.view.deleteTraceLine(roiId);

            self.view.unselectRoiPatch(roiPatch);
            slRoi = getappdata(roiPatch,'roiHandle');
            self.model.unselectRoi(slRoi);
        end

        function selectAllRoi(self)
            roiPatchArray = getRoiPatchArray(self.view);
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                self.selectRoi(roiPatch);
            end
        end
        
        function deleteRoi(self)
            slRoiPatchArray = self.view.getSelectedRoiPatchArray;
            for i=1:length(slRoiPatchArray)
                slRoiPatch = slRoiPatchArray(i);
                slRoi = getappdata(slRoiPatch,'roiHandle');
                self.model.deleteRoi(slRoi);
                self.view.deleteRoiPatch(slRoiPatch);
            end 
        end
        
        function roi = copyRoi(self)
            currentRoi = self.model.currentRoi;
            roi = copy(currentRoi)
        end
                
        function addRoiArray(self,roiArray)
            cellfun(@(x) self.addRoi(x), roiArray);
        end

        function freshRoiArray = copyRoiArray(self)
            roiArray = self.model.getRoiArray();
            freshRoiArray = cellfun(@copy,roiArray, ...
                                    'UniformOutput',false);
            
        end
        
        function saveRoiArray(self,filePath)
            if exist(filePath, 'file') == 2
                promptStr = sprintf(['The file %s already exists.\nDo you want ' ...
                             'to replace it? Y/n [n]'],filePath);
                replaceStr = input(promptStr,'s');
                while ~strcmp(replaceStr,'Y') && ~ ...
                        strcmp(replaceStr,'n')
                    replaceStr = input('Please enter Y or n: ','s');
                end
                if ~strcmp(replaceStr,'Y')
                    disp('Not saving the ROI array.')
                    return
                end
            end
            NrModel.saveRoiArray(self.model,filePath)
            disp(sprintf('ROI array saved as %s',filePath));
        end
        
        function loadRoiArray(self,filePath)
            foo = load(filePath);
            roiArray = foo.roiArray;
            self.addRoiArray(roiArray);
        end
        
        
    end
    
    methods
        function closeGUI(self,src,event)
            selection = questdlg('Close MyGUI?', ...
                                 'Warning', ...
                                 'Yes','No','Yes');
            switch selection
              case 'Yes'
                delete(src)
              case 'No'
                return
            end
        end
    end

end
