classdef BaseTrialView < handle
    properties
        model
        controller
        guiHandles
        selectedMarkers
        mapColorMap
        mapSize
        zoom
        roiColorMap
        AlphaForRoiOnePatch = 0.5
        roiVisible
        
        contrastLimArray
    end
    
    properties (Access = private)
        roiMask
    end

    properties (Constant)
        DEFAULT_PATCH_COLOR = 'red'
    end


    
    methods
        
        function self = BaseTrialView(mymodel, mycontroller)
            self.model = mymodel;
            self.controller = mycontroller;
            self.roiMask = zeros(self.model.roiArr.imageSize);
        end
        
        function listenToModel(self)
            addlistener(self.model,'roiAdded',@self.drawLastRoiPatch);
            addlistener(self.model,'roiSelected',...
                        @self.updateRoiPatchSelection);
            addlistener(self.model,'roiDeleted',...
                        @self.deleteRoiPatches);
            addlistener(self.model,'roiNewAlpha',...
                        @self.UpdateRoiPatchAlpha);
            addlistener(self.model,'roiNewAlphaAll',...
                        @self.UpdateAllRoiPatchAlpha);
            addlistener(self.model,'roiUpdated',...
                        @self.updateRoiPatchPosition);
            addlistener(self.model,'roiTagChanged',...
                        @self.changeRoiPatchTag);
            addlistener(self.model,'roiArrReplaced',...
                        @(~,~)self.drawAllRoisOverlay());        
        end

        function assignCallbacks(self)
            set(self.guiHandles.mainFig,'WindowKeyPressFcn',...
                              @(s,e)self.controller.keyPressCallback(s,e));
            set(self.guiHandles.mainFig,'WindowScrollWheelFcn',...
                              @(s,e)self.controller.ScrollWheelFcnCallback(s,e));
            
            set(self.guiHandles.contrastMinSlider,'Callback',...
                              @(s,e)self.controller.contrastSlider_Callback(s,e));
            set(self.guiHandles.contrastMaxSlider,'Callback',...
                              @(s,e)self.controller.contrastSlider_Callback(s,e));

            % Save original settings for zoom
            self.zoom.origXLim = self.guiHandles.mapAxes.XLim;
            self.zoom.origYLim = self.guiHandles.mapAxes.YLim;
            self.zoom.maxZoomScrollCount = 30;
            self.zoom.scrollCount = 0;

            helper.imgzoompan(self.guiHandles.mainFig,...
                              self.guiHandles.roiAxes,...
                              self.guiHandles.mapAxes,...
                              'ButtonDownFcn',@(s,e) self.controller.roiClicked_Callback(s,e),...
                              'ImgHeight',self.mapSize(1),'ImgWidth',self.mapSize(2));
        end
        
        % Maps
        function displayCurrentMap(self)
            map = self.model.getCurrentMap();
            if ~isempty(map)
                self.plotMap(map);
                self.showMapOption(map);
                self.updateContrastForCurrentMap();
            end
        end
        
        function showMapOption(self,map)
            optionStr = trialMvc.TrialView.convertOptionToString(map.option);
            self.guiHandles.mapOptionText.String = optionStr;
        end
        
        % ROIs
        function loadRoiColormap(self)
            [funcDir, ~, ~]= fileparts(mfilename('fullpath'));
            neuRoiDir = fullfile(funcDir,'..');
            cmapDir = fullfile(neuRoiDir,'colormap');
            roiCmapPath = fullfile(cmapDir,'roicolormap.mat');
            try
                foo = load(roiCmapPath);
                self.roiColorMap = foo.roicolormap;
            catch ME
                self.roiColorMap = 'lines';
            end
        end

        % Methods for ROI based processing
        function drawLastRoiPatch(self,src,evnt)
            roi = self.model.roiArr.getLastRoi();
            self.addRoiPatch(roi);
        end

        function drawAllRoisOverlay(self)
            mapAxes = self.guiHandles.mapAxes;
            roiMask = self.model.roiArr.convertToMask();
            roiGroupMask = self.model.roiArr.convertToGroupMask();
            self.setRoiImgData(roiMask, roiGroupMask)
        end

        function roiMask = getRoiMask(self)
            roiMask = self.roiMask;
        end
        
        function setRoiImgData(self, roiMask, roiGroupMask)
            self.roiMask = roiMask;
            climits = [0, 20];
            if isfield(self.guiHandles,'roiImg')
                self.guiHandles.roiImg.CData = roiGroupMask;
                self.guiHandles.roiImg.AlphaData = (roiGroupMask > 0) * self.AlphaForRoiOnePatch;
                caxis(climits)
            else
                self.guiHandles.roiImg = imagesc(roiGroupMask,'Parent',self.guiHandles.roiAxes);
                set(self.guiHandles.roiAxes,'color','none','visible','off')
                self.guiHandles.roiImg.AlphaData = (roiGroupMask > 0) * self.AlphaForRoiOnePatch;
                colormap(self.guiHandles.roiAxes,self.roiColorMap);
                self.setRoiVisibility(self.roiVisible);
                caxis(climits) % set color range, so each color corresponds to a fixed value
            end
        end

        function addRoiPatch(self,roi)
            roiGroupMask = self.guiHandles.roiImg.CData;
            groupTag = roi.meta.groupTag;
            roiGroupMask = roi.addMaskToImg(roiGroupMask, groupTag);
            roiMask = roi.addMaskToImg(self.roiMask);
            
            self.setRoiImgData(roiMask, roiGroupMask);
            self.setRoiVisibility(true);
        end
        
        function deleteRoiPatch(self, roi)
            roiGroupMask = self.guiHandles.roiImg.CData;
            roiGroupMask = roi.addMaskToImg(roiGroupMask, 0);
            roiMask = roi.addMaskToImg(self.roiMask, 0);
            
            self.setRoiImgData(roiMask, roiGroupMask);
        end
        
        function updateRoiPatchPosition(self,src,evnt)
            newRoi = evnt.newRoi;
            oldRoi = evnt.oldRoi;
            % Remove original ROI in roiImg
            self.deleteRoiPatch(oldRoi);
            % Add updated ROI to roiImg
            self.addRoiPatch(newRoi);
            % Move selection cross
            self.updateRoiPatchSelection();
        end
        
        
        function updateRoiPatchGroup(self, src, evnt)
            roi = evnt.roi;
            self.addRoiPatch(roi);
        end

        function deleteRoiPatches(self,src,evnt)
            rois = evnt.rois;
            roiGroupMask = self.guiHandles.roiImg.CData;
            roiMask = self.roiMask;
            for k=1:length(rois)
                % Remove ROI in roiImg
                roi = rois(k);
                roiGroupMask = roi.addMaskToImg(roiGroupMask, 0);
                roiMask = roi.addMaskToImg(roiMask, 0);
            end
            self.setRoiImgData(roiMask, roiGroupMask);
            self.updateRoiPatchSelection()
        end
        
        % function displayRoiTag(self,roiPatch)
        %     ptTag = get(roiPatch,'Tag');
        %     tag = helper.convertTagToInd(ptTag,'roi');
        %     pos = roiPatch.Vertices(1,:);
        %     htext = text(self.guiHandles.roiGroup,pos(1),pos(2), ...
        %                  num2str(tag),'FontSize',8,'Color','m');
        %     htext.Tag = sprintf('roiTag_%d',tag);
        % end
        
        % function removeRoiTagText(self,roiTag)
        %     txtTag = sprintf('roiTag_%d',roiTag);
        %     htext = findobj(self.guiHandles.roiGroup,...
        %                     'Type','text',...
        %                     'Tag',txtTag);
        %     delete(htext);
        % end
        
        function updateRoiPatchSelection(self,src,evnt)
            roiList = self.model.roiArr.getSelectedRois();
            delete(self.selectedMarkers);
            nRois = length(roiList);
            centroids = zeros(nRois, 2);
            for k=1:nRois
                roi = roiList(k);
                centroids(k, :) = roi.getCentroid();
            end
            hold on;
            self.selectedMarkers = plot(centroids(:,1), centroids(:,2), '+',...
                                        'color', '#77AC30', 'MarkerSize', 10, 'LineWidth', 1);
            hold off;
        end
        
        
        % function roiPatch = findRoiPatchByTag(self,tag)
        %     ptTag = RoiFreehand.getPatchTag(tag);
        %     roiPatch = findobj(self.guiHandles.roiGroup,...
        %                        'Type','patch',...
        %                        'tag',ptTag);
        %     if isempty(roiPatch)
        %         error(sprintf('ROI #%d not found!',tag))
        %     end
        % end

        % function UpdateRoiPatchAlpha(self,src,evnt)
        %     updRoiArray=evnt.roiArray;
        %     for k=1:length(updRoiArray)
        %         roi = updRoiArray(k);
        %         roiPatch = self.findRoiPatchByTag(roi.tag);
        %         roi.UpdateRoiPatchAlpha(roiPatch);
        %     end
        % end

        % function UpdateAllRoiPatchAlpha(self,src,evnt)
        %     if evnt.AllRois==true
        %         for k=1:length(self.guiHandles.roiGroup.Children)
        %             roiPatch = self.guiHandles.roiGroup.Children(k);
        %             set(roiPatch,'FaceAlpha',evnt.NewAlpha);
        %         end
        %     end
        % end

        % function changeRoiPatchTag(self,src,evnt)
        %     oldTag = evnt.oldTag;
        %     newTag = evnt.newTag;
        %     roiPatch = self.findRoiByTag(evnt.oldTag);
        %     roiPatch.tag = RoiFreehand.getPatchTag(newTag);
        % end
        
        % function roiPatchArray = getRoiPatchArray(self)
        %     mapAxes = self.guiHandles.roiGroup;
        %     children = mapAxes.Children;
        %     patchInd = arrayfun(@RoiFreehand.isaRoiPatch,children);
        %     roiPatchArray = children(patchInd);
        % end
        
        % function deleteAllRoiPatch(self)
        %     roiPatchArray = self.getRoiPatchArray();
        %     arrayfun(@(x) delete(x), roiPatchArray);
        % end

        function setRoiVisibility(self, roiVisible)
            self.roiVisible = roiVisible;
            if self.roiVisible
                roiState = 'on';
            else
                roiState = 'off';
            end
            set(self.guiHandles.roiImg,'Visible',roiState);
        end
        
        function roiPatch = createMovableRoi(self)
            if ~self.model.singleRoiSelected()
                error('Please select a single ROI!')
            end
            ptcolor = 'yellow';
            roi = self.model.roiArr.getSelectedRois();
            imageSize = size(self.guiHandles.mapImage.CData);
            poly = roiFunc.mask2poly(roi.createMask(imageSize));
            
            roiPatch = patch(poly.X, poly.Y, ptcolor,...
                             'Parent', self.guiHandles.roiAxes);
            set(roiPatch,'FaceAlpha', 0.5);
            set(roiPatch,'EdgeColor','blue');
            ptTag = sprintf('roi_%d', roi.tag);
            set(roiPatch,'Tag',ptTag);
        end
        
        
        
        % Methods for changing contrast
        function updateContrastForCurrentMap(self)
            [dataLim,contrastLim] = self.getDataLimAndContrastLim();
            self.setDataLimAndContrastLim(dataLim, contrastLim);
            self.changeMapContrast(contrastLim);
            self.saveContrastLim(contrastLim);
        end
        
        function contrastLim = getContrastLim(self, dataLim)
            error('Not implemented')
        end
        
        function saveContrastLim(self, contrastLim)
            error('Not implemented')
        end
        
        function changeMapContrast(self,contrastLim)
        % Usage: myview.changeMapContrast(contrastLim), contrastLim
        % is a 1x2 array [cmin cmax]
            caxis(self.guiHandles.mapAxes,contrastLim);
        end
        
        function setDataLimAndContrastLim(self,dataLim,contrastLim)
            contrastSliderArr = self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                cs = contrastSliderArr(end+1-k);
                set(cs,'Min',dataLim(1),'Max',dataLim(2),...
                       'Value',contrastLim(k));
            end
        end

        function dataLim = getContrastSliderDataLim(self)
            contrastSliderArr = self.guiHandles.contrastSliderGroup.Children;
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
        
        function contrastLim = getContrastSlidertLim(self)
            contrastSliderArr = self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastLim(k) = contrastSliderArr(end+1-k).Value;
            end
        end
        
        function setContrastLim(self,contrastLim)
            contrastSliderArr = self.guiHandles.contrastSliderGroup.Children;
            for k=1:2
                contrastSliderArr(end+1-k).Value = contrastLim(k);
            end
        end
        
        
        % Zoom
        function zoomFcn(self,scrollChange)
            opt.Magnify = 1.1;
            opt.XMagnify = 1.0;
            opt.YMagnify = 1.0;
            imgWidth = self.mapSize(2);
            imgHeight = self.mapSize(1);

            if ((self.zoom.scrollCount - scrollChange) <= ...
                self.zoom.maxZoomScrollCount)

                % calculate the new XLim and YLim
                axish = self.guiHandles.roiAxes;
                cpaxes = mean(axish.CurrentPoint);
                newXLim = (axish.XLim - cpaxes(1)) * (opt.Magnify * opt.XMagnify)^scrollChange + cpaxes(1);
                newYLim = (axish.YLim - cpaxes(2)) * (opt.Magnify * opt.YMagnify)^scrollChange + cpaxes(2);

                newXLim = floor(newXLim);
                newYLim = floor(newYLim);
                
                hAxesList = {self.guiHandles.roiAxes,...
                             self.guiHandles.mapAxes};
                % Check for image border location
                if (newXLim(1) >= 0 && newXLim(2) <= imgWidth && newYLim(1) >= 0 && newYLim(2) <= imgHeight)
                    for k=1:length(hAxesList)
                        axish = hAxesList{k};
                        axish.XLim = newXLim;
                        axish.YLim = newYLim;
                    end
                    self.zoom.scrollCount = self.zoom.scrollCount - scrollChange;
                else
                    for k=1:length(hAxesList)
                        axish = hAxesList{k};
                        axish.XLim = self.zoom.origXLim;
                        axish.YLim = self.zoom.origYLim;
                    end
                    self.zoom.scrollCount = 0;
                end
            end
        end
        

    end
    
end
