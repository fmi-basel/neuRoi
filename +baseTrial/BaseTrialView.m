classdef BaseTrialView < handle
   properties
        model
        controller
        guiHandles
        selectedRoiPatchArray
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
            addlistener(self.model,'selectedRoiTags','PostSet',...
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
                        @(~,~)self.redrawAllRoiPatch());        
        end

        function assignCallbacks(self)
            set(self.guiHandles.mainFig,'WindowKeyPressFcn',...
                              @(s,e)self.controller.keyPressCallback(s,e));
            set(self.guiHandles.mainFig,'WindowScrollWheelFcn',...
                              @(s,e)self.controller.ScrollWheelFcnCallback(s,e));
        end

        % Methods for ROI based processing
        function drawLastRoiPatch(self,src,evnt)
            roi = src.getRoiByTag('end');
            self.addRoiPatch(roi);
        end

        function deleteAllRoiAsOnePatch(self)
            mapAxes = self.guiHandles.roiGroup;
            children = mapAxes.Children;
            delete(children);
        end

        function redrawAllRoiAsOnePatch(self)
            mapAxes = self.guiHandles.roiGroup;
            children = mapAxes.Children;
            delete(children);
            roiArray = self.model.getRoiArray();
            parentAxes = self.guiHandles.roiGroup.Parent;
            maxlength=0;
            for i = 1:length(roiArray)
                dimension=size(roiArray(i).position);
                if dimension(1)>maxlength
                    maxlength=dimension(1);
                end
            end
            Xcoor=nan(maxlength,length(roiArray));
            Ycoor=nan(maxlength,length(roiArray));
            for i = 1:length(roiArray)
                axesPos =getAxesPosition(parentAxes,roiArray(i).position);
                Xcoor(1:length(axesPos(:,1)),i)=axesPos(:,1);
                Ycoor(1:length(axesPos(:,2)),i)=axesPos(:,2);
            end
            

            Xcoor= fillmissing(Xcoor,'previous',1); %need to replace nan with previous values, patch should work with nan but i got some error with display so i just replace them
            Ycoor= fillmissing(Ycoor,'previous',1);
           
            roiPatch = patch(Xcoor,Ycoor,'red','Parent',self.guiHandles.roiGroup);
            set(roiPatch,'FaceAlpha',self.AlphaForRoiOnePatch);
            set(roiPatch,'LineStyle','none');
            
            set(roiPatch,'Tag',"AllRois");

            %roiPatch.UIContextMenu = self.guiHandles.roiMenu;
        end

         function redrawAllRoiPatch(self)
            self.deleteAllRoiPatch();
            roiArray = self.model.getRoiArray();
            arrayfun(@(x) self.addRoiPatch(x),roiArray);
        end

         function addRoiPatch(self,roi)
            roiPatch = roi.createRoiPatch(self.guiHandles.roiGroup, ...
                                          self.DEFAULT_PATCH_COLOR);
            % Add context menu for right click
            roiPatch.UIContextMenu = self.guiHandles.roiMenu;
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
            newTagArray = evnt.AffectedObject.selectedRoiTagArray;
            for k=1:length(self.selectedRoiPatchArray)
                roiPatch = self.selectedRoiPatchArray{k};
                roiPatch.Selected = 'off';
                roiTag = helper.convertTagToInd(roiPatch.Tag,'roi');
                self.removeRoiTagText(roiTag);
            end
            self.selectedRoiPatchArray = {};
            for k=1:length(newTagArray)
                tag = newTagArray(k);
                roiPatch = self.findRoiPatchByTag(tag);
                roiPatch.Selected = 'on';
                self.displayRoiTag(roiPatch);
                uistack(roiPatch,'top') % bring the selected roi
                                        % patch to front of the
                                        % image and number tag
                self.selectedRoiPatchArray{k} = roiPatch;
            end
        end
        
        function changeRoiPatchColor(self,ptcolor,varargin)
            if nargin == 3
                if strcmp(ptcolor,'default')
                    ptcolor = self.DEFAULT_PATCH_COLOR;
                end
                for k=1:length(self.selectedRoiPatchArray)
                    roiPatch = self.selectedRoiPatchArray{k};
                    set(roiPatch,'Facecolor',ptcolor);
                end
            end
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
            updRoiArray = evnt.roiArray;
            for k=1:length(updRoiArray)
                roi = updRoiArray(k);
                roiPatch = self.findRoiPatchByTag(roi.tag);
                roi.updateRoiPatchPos(roiPatch);
            end
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


