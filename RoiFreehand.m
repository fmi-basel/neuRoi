classdef RoiFreehand < handle
    properties
        id
        position
        imageSize
    end
    
    methods
        function self = RoiFreehand(varargin)
            if nargin == 2
                if isnumeric(varargin{1})
                    self.imageSize = varargin{1};
                    self.position = varargin{2};
                elseif ishandle(varargin{1})
                    parent = varargin{1};
                    roiRaw = varargin{2};
                    axesPosition = roiRaw.getPosition();
                    self.imageSize = size(getimage(parent));
                    self.position = ...
                        getPixelPosition(parent,axesPosition);
                else
                    error('Wrong usage!')
                end
            else
                error('Wrong usage!')
            end
        end
        
        function mask = createMask(self)
            mask = poly2mask(self.position(:,1),...
                             self.position(:,2),...
                             self.imageSize(1),...
                             self.imageSize(2));
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
            
            inputImageSize = size(getimage(parent));
            if ~isequal(inputImageSize,self.imageSize)
                warning(['Input image size not equal to ROI image ' ...
                         'size!'])
            end

            pixelPosition = self.position;
            axesPosition = getAxesPosition(parent,pixelPosition);
            roiPatch = patch(axesPosition(:,1),axesPosition(:,2),ptcolor,'Parent',parent);
            set(roiPatch,'FaceAlpha',0.5)
            set(roiPatch,'LineStyle','none');
            set(roiPatch,'Tag',sprintf('roi_%04d',self.id))
            setappdata(roiPatch,'roiHandle',self);
            % moveit2(roiPatch)
        end
    end
end

function pixelPos = getPixelPosition(parent,axesPos)
    [xdata,ydata,cdata] = getimage(parent);
    imageSize = size(cdata);

    if isDefaultCoordinate(imageSize,xdata,ydata)
        axesPos = pixelPos;
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
        disp('default coordinates')
    else
        tf = false;
        disp('not default coordinates')
    end
end
