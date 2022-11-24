classdef BaseTrialView < handle
    properties
        model
        controller
        guiHandles
        selectedMarkers
        mapColorMap
        mapSize
        zoom
        AlphaForRoiOnePatch = 0.5
    end

    properties (Constant)
        DEFAULT_PATCH_COLOR = 'red'
    end


    
    methods
        function listenToModel(self)
            addlistener(self.model,'roiVisible','PostSet',...
                        @self.changeRoiVisibility);
            addlistener(self.model,'roiAdded',@self.drawLastRoiPatch);
            addlistener(self.model,'roiSelected',...
                        @self.updateRoiPatchSelection);
            addlistener(self.model,'roiDeleted',...
                        @self.deleteRoiPatch);
            addlistener(self.model,'roiNewAlpha',...
                        @self.UpdateRoiPatchAlpha);
            addlistener(self.model,'roiNewAlphaAll',...
                        @self.UpdateAllRoiPatchAlpha);
            addlistener(self.model,'roiUpdated',...
                        @self.updateRoiPatchPosition);
            addlistener(self.model,'roiTagChanged',...
                        @self.changeRoiPatchTag);
            addlistener(self.model,'roiArrayReplaced',...
                        @(~,~)self.drawAllRoisOverlay());        
        end

        function assignCallbacks(self)
            set(self.guiHandles.mainFig,'WindowKeyPressFcn',...
                              @(s,e)self.controller.keyPressCallback(s,e));
            set(self.guiHandles.mainFig,'WindowScrollWheelFcn',...
                              @(s,e)self.controller.ScrollWheelFcnCallback(s,e));
            
            helper.imgzoompan(self.guiHandles.roiAxes,...
                              'ButtonDownFcn',@(s,e) self.controller.selectRoi_Callback(s,e),...
                              'ImgHeight',self.mapSize(1),'ImgWidth',self.mapSize(2));

        end

        % Methods for ROI based processing
        function drawLastRoiPatch(self,src,evnt)
            roi = self.model.roiArr.getLastRoi();
            self.addRoiPatch(roi);
        end

        function deleteAllRoiAsOnePatch(self)
            mapAxes = self.guiHandles.roiGroup;
            children = mapAxes.Children;
            delete(children);
        end

        function drawAllRoisOverlay(self)
            mapAxes = self.guiHandles.mapAxes;
            roiImgData = self.model.roiArr.convertToMask();
            self.setRoiImgData(roiImgData)
        end

        function roiImgData = getRoiImgData(self)
            if isfield(self.guiHandles,'roiImg')
                roiImgData = self.guiHandles.roiImg.CData;
            else
                roiImgData = [];
            end
        end
        
        function setRoiImgData(self, roiImgData)
            if isfield(self.guiHandles,'roiImg')
                self.guiHandles.roiImg.CData = roiImgData;
                self.guiHandles.roiImg.AlphaData = (roiImgData > 0) * self.AlphaForRoiOnePatch;
            else
                self.guiHandles.roiImg = imagesc(roiImgData,'Parent',self.guiHandles.roiAxes);
                set(self.guiHandles.roiAxes,'color','none','visible','off')
                self.guiHandles.roiImg.AlphaData = (roiImgData > 0) * self.AlphaForRoiOnePatch;
                colormap(self.guiHandles.roiAxes,self.roiColorMap);
                self.setRoiVisibility();
            end
        end

        function addRoiPatch(self,roi)
            if isfield(self.guiHandles,'roiImg')
                roiImgData = self.guiHandles.roiImg.CData;
                self.setRoiImgData(roi.addMaskToImg(roiImgData));
            end
        end
        
        function displayRoiTag(self,roiPatch)
            ptTag = get(roiPatch,'Tag');
            tag = helper.convertTagToInd(ptTag,'roi');
            pos = roiPatch.Vertices(1,:);
            htext = text(self.guiHandles.roiGroup,pos(1),pos(2), ...
                         num2str(tag),'FontSize',8,'Color','m');
            htext.Tag = sprintf('roiTag_%d',tag);
        end
        
        function removeRoiTagText(self,roiTag)
            txtTag = sprintf('roiTag_%d',roiTag);
            htext = findobj(self.guiHandles.roiGroup,...
                            'Type','text',...
                            'Tag',txtTag);
            delete(htext);
        end
        
        
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
            self.selectedMarkers = plot(centroids(:,1), centroids(:,2),...
                                        'r+', 'MarkerSize', 10, 'LineWidth', 1);
            hold off;
        end
        
        
        function roiPatch = findRoiPatchByTag(self,tag)
            ptTag = RoiFreehand.getPatchTag(tag);
            roiPatch = findobj(self.guiHandles.roiGroup,...
                               'Type','patch',...
                               'tag',ptTag);
            if isempty(roiPatch)
                error(sprintf('ROI #%d not found!',tag))
            end
        end

        function UpdateRoiPatchAlpha(self,src,evnt)
            updRoiArray=evnt.roiArray;
            for k=1:length(updRoiArray)
                roi = updRoiArray(k);
                roiPatch = self.findRoiPatchByTag(roi.tag);
                roi.UpdateRoiPatchAlpha(roiPatch);
            end
        end

        function UpdateAllRoiPatchAlpha(self,src,evnt)
            if evnt.AllRois==true
                for k=1:length(self.guiHandles.roiGroup.Children)
                    roiPatch = self.guiHandles.roiGroup.Children(k);
                    set(roiPatch,'FaceAlpha',evnt.NewAlpha);
                end
            end
        end

        function updateRoiPatchPosition(self,src,evnt)
            newRoi = evnt.newRoi;
            oldRoi = evnt.oldRoi;
            % Remove original ROI in roiImg
            roiImgData = self.getRoiImgData();
            roiImgData = oldRoi.addMaskToImg(roiImgData, 0);
            % Add updated ROI to roiImg
            roiImgData = newRoi.addMaskToImg(roiImgData);
            self.setRoiImgData(roiImgData);
        end
        
        function changeRoiPatchTag(self,src,evnt)
            oldTag = evnt.oldTag;
            newTag = evnt.newTag;
            roiPatch = self.findRoiByTag(evnt.oldTag);
            roiPatch.tag = RoiFreehand.getPatchTag(newTag);
        end
        
        
        function roiPatchArray = getRoiPatchArray(self)
            mapAxes = self.guiHandles.roiGroup;
            children = mapAxes.Children;
            patchInd = arrayfun(@RoiFreehand.isaRoiPatch,children);
            roiPatchArray = children(patchInd);
        end
        
        function deleteAllRoiPatch(self)
            roiPatchArray = self.getRoiPatchArray();
            arrayfun(@(x) delete(x), roiPatchArray);
        end

        function deleteRoiPatch(self,src,evnt)
            tagArray = evnt.tagArray;
            for k=1:length(tagArray)
                roiPatch = self.findRoiPatchByTag(tagArray(k))'
                delete(roiPatch);
            end
        end
        
        function changeRoiVisibility(self,src,evnt)
            if self.model.roiVisible
                roiState = 'on';
            else
                roiState = 'off';
            end
            set(self.guiHandles.roiGroup,'Visible',roiState);
        end
        
    end
    
end

function pixelPos = getPixelPosition(parent,axesPos)
    [xdata,ydata,cdata] = getimage(parent);
    imageSize = size(cdata);

    if isDefaultCoordinate(imageSize,xdata,ydata)
        pixelPos = axesPos;
    else
        [xWorldLim,yWorldLim] = getWorldLim(imageSize,xdata,ydata);
        refObj = imref2d(imageSize,xWorldLim,yWorldLim);
        [posx,posy] = worldToIntrinsic(refObj,...
                                       axesPos(:,1),axesPos(:,2));
        pixelPos = [posx,posy];
    end
end

function axesPos = getAxesPosition(parent,pixelPos)
% GETAXESPOSITON convert postion in intrinsic coordinates into world
% coordinates.
% Usage: axesPos = getAxesPosition(parent,pixelPos)
% parent can be a handle of an image, or a handle that contains
% image as children
    
    [xdata,ydata,cdata] = getimage(parent);
    imageSize = size(cdata);

    if isDefaultCoordinate(imageSize,xdata,ydata)
        axesPos = pixelPos;
    else
        [xWorldLim,yWorldLim] = getWorldLim(imageSize,xdata,ydata);
        refObj = imref2d(imageSize,xWorldLim,yWorldLim);
        [posx,posy] = intrinsicToWorld(refObj,...
                                       pixelPos(:,1),pixelPos(:,2));
        axesPos = [posx,posy];
    end
end

function [xWorldLim,yWorldLim] = getWorldLim(imageSize,xdata,ydata)
    pixelExtentInWorldX = (xdata(2)-xdata(1))/imageSize(2);
    xWorldLim = [xdata(1)-pixelExtentInWorldX*0.5,...
                 xdata(2)+pixelExtentInWorldX*0.5];
    pixelExtentInWorldY = (ydata(2)-ydata(1))/imageSize(1);
    yWorldLim = [ydata(1)-pixelExtentInWorldY*0.5,...
                 ydata(2)+pixelExtentInWorldY*0.5];
end

function tf = isDefaultCoordinate(imageSize,xdata,ydata)
    if isequal(xdata,[1 imageSize(2)]) && isequal(ydata,[1 imageSize(1)])
        tf = true;
    else
        tf = false;
    end
end


