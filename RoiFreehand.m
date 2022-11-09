classdef RoiFreehand
    properties
        tag
        position
        offsetYx
        posErr
        type
        AlphaValue =0.5
        roiGroup
    end
    
    methods
        function self = RoiFreehand(varargin)
            if nargin == 1
                % Create ROI from pixel position
                position = varargin{1};
            elseif nargin == 2
                % Create ROI from patch object in axes position
                parent = varargin{1};
                if ishandle(parent)
                    axesPosition = varargin{2};
                    imageSize = size(getimage(parent));
                    position = getPixelPosition(parent, ...
                                                axesPosition);
                else
                    error('Wrong usage!')
                end
            else
                error('Wrong usage!')
            end
            
            if isempty(position) || ~isequal(size(position,2),2)
                error('Invalid Position!')
            end
            self.position = position;
            self.AlphaValue=0.5;
            self.roiGroup="Default";
        end
        
        function mask = createMask(self,imageSize)
        % TODO imageSize should include the position of ROI
            mask = poly2mask(self.position(:,1),...
                             self.position(:,2),...
                             imageSize(1),...
                             imageSize(2));
        end
        
        function roiPatch = createRoiPatch(self,parent,ptcolor)
        % CREATEROIPATCH create a patch handle according to ROI position
        % for visualization
        % Usage: createRoiPatch(roi,parent)
        % roi: the handle to a RoiFreehand object
        % parent: the handle to the parent to which the patch is attached
            
            if ~exist('parent', 'var')
                parent = gca;
            end

            if ~exist('ptcolor', 'var')
                ptcolor = 'red';
            end
            
            try
                inputImageSize = size(getimage(parent));
                parentAxes = parent;
            catch ME
                try
                    % if the parent is a group, get imageSize from
                    % the parent axes of the group
                    inputImageSize = size(getimage(parent.Parent));
                    parentAxes = parent.Parent;
                catch ME
                    rethrow ME
                end
            end
            
            pixelPosition = self.position;
            axesPosition = getAxesPosition(parentAxes,pixelPosition);
            roiPatch = patch(axesPosition(:,1),axesPosition(:,2),ptcolor,'Parent',parent);
            set(roiPatch,'FaceAlpha',self.AlphaValue);
            set(roiPatch,'LineStyle','none');
            ptTag = RoiFreehand.getPatchTag(self.tag);
            set(roiPatch,'Tag',ptTag);
        end

        function UpdateRoiPatchAlpha(self,roiPatch)
            if (0<=self.AlphaValue)&&(self.AlphaValue<=1)
                set(roiPatch,'FaceAlpha',self.AlphaValue);
            end   
        end

        function ChangeRoiPatchAlpha(self,roiPatch,NewAlpha) %Maybe not needed
            if (0<NewAlpha)&&(NewAlpha<1)
                self.AlphaValue = NewAlpha;
                set(roiPatch,'FaceAlpha',self.AlphaValue);
            end   
        end
        
        function updateRoiPatchPos(self,roiPatch)
            offsetYx = self.offsetYx;
            offsetFlag = any(offsetYx);
            parent = ancestor(roiPatch,'Axes');
            pixelPosition = self.position;
            if offsetFlag
                pixelPosition = pixelPosition + [offsetYx(2), ...
                                    offsetYx(1)];
            end
            axesPosition = getAxesPosition(parent,pixelPosition);
            set(roiPatch,'XData',axesPosition(:,1),'YData', ...
                         axesPosition(:,2));
            if offsetFlag
                %set(roiPatch,'FaceAlpha',0.5);
                set(roiPatch,'LineStyle','-');
                set(roiPatch,'UserData','offset');
                cmap = jet(256);
                errColorIdx = max(1,round(self.posErr*length(cmap)));
                disp(errColorIdx)
                fcolor = cmap(errColorIdx,:);
                set(roiPatch,'FaceColor',fcolor);
            else
                if strcmp(get(roiPatch,'UserData'),'offset')
                    % TODO reset to default face color
                    %set(roiPatch,'FaceAlpha',0.5);
                    set(roiPatch,'LineStyle','none');
                    set(roiPatch,'UserData',[]);
                end
            end
        end
        
        function offsetYx = matchPos(self,inputImg,tempImg, ...
                                        windowSize,fitGauss,normFlag,plotFlag)
            if ~exist('fitGauss','var')
                fitGauss=1;
            end
                
            if ~exist('plotFlag','var')
                plotFlag=0;
            end
            
            mask = self.createMask();
            [maskIndX,maskIndY] = find(mask==1);
            xmin = max(min(maskIndX)-windowSize,1);
            xmax = min(max(maskIndX)+windowSize,size(inputImg,1));
            ymin = max(min(maskIndY)-windowSize,1);
            ymax = min(max(maskIndY)+windowSize,size(inputImg,2));
            inputRimg = inputImg(xmin:xmax,ymin:ymax);
            tempRimg = tempImg(xmin:xmax,ymin:ymax);
            if plotFlag
                figure
                imagesc(inputRimg)
                title('input')
                figure
                imagesc(tempRimg)
                title('temp')
            end
            [self.offsetYx,self.posErr] = movieFunc.alignImage(inputRimg, ...
                                                 tempRimg,fitGauss,normFlag,plotFlag);
        end
        
        function acceptShift(self)
            offsetYx = self.offsetYx;
            self.position = self.position + [offsetYx(2),offsetYx(1)];
        end
        
        function rejectShift(self,roiPatch)
            self.offsetYx = [0, 0];
        end
    end
    
    methods (Static)
        function result = isaRoiPatch(hobj)
            result = false;
            if ~isempty(hobj)
                if ishandle(hobj) && isvalid(hobj) && isprop(hobj,'Tag')
                    tag = get(hobj,'Tag');
                    if strfind(tag,'roi_')
                        result = true;
                    end
                end
            end
        end
        
        function ptTag = getPatchTag(tag)
            ptTag = sprintf('roi_%04d',tag);
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
