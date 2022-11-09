function startmovit(src)
% STARTMOVIT move multiple graphical objects
% Adapted from the moveit2.m
% Original author: Anders Brun, anders@cb.uu.se

thisFig = ancestor(src,'figure');
gui = get(thisFig,'UserData');
gui.moveitData.currentHandle = src;

% Remove mouse pointer
set(gcf,'PointerShapeCData',nan(16,16));
set(gcf,'Pointer','custom');

gui.moveitData.oldWindowButtonMotionFcn = ...
    get(thisFig,'WindowButtonMotionFcn');
gui.moveitData.oldWindowButtonUpFcn = ...
    get(thisFig,'WindowButtonUpFcn');

set(thisFig,'WindowButtonMotionFcn',@movit);
set(thisFig,'WindowButtonUpFcn',@stopmovit);

% Store starting point of the object
thisAxes = get(thisFig,'CurrentAxes');
gui.moveitData.startPoint = get(thisAxes,'CurrentPoint');
srcData = get(gui.moveitData.currentHandle,'UserData');
srcData.moveitData.XYData = {get(src,'XData') get(src,'YData')};
set(src,'UserData',srcData)

% Store gui object
set(thisFig,'UserData',gui);


function movit(src,evnt)
thisFig = gcbf();
thisAxes = get(thisFig,'CurrentAxes');

% Unpack gui object
gui = get(thisFig,'UserData');

try
if isequal(gui.moveitData.startPoint,[])
    return
end
catch
end

% Do "smart" positioning of the object, relative to starting point...
pos = get(thisAxes,'CurrentPoint')-gui.moveitData.startPoint;
srcData = get(gui.moveitData.currentHandle,'UserData');
XYData = srcData.moveitData.XYData;

set(gui.moveitData.currentHandle,'XData',XYData{1} + pos(1,1));
set(gui.moveitData.currentHandle,'YData',XYData{2} + pos(1,2));

drawnow;

% Store gui object
gui.moveitData.pos = pos;
set(thisFig,'UserData',gui);

function stopmovit(src,evnt)

% Clean up the evidence ...

thisFig = gcbf();
gui = get(thisFig,'UserData');

% Restore UserData in moved object
srcData = get(gui.moveitData.currentHandle,'UserData');
rmfield(srcData,'moveitData');
set(gui.moveitData.currentHandle,'UserData',srcData);

% Restore Callback of parent figure
set(thisFig,'WindowButtonUpFcn',...
    gui.moveitData.oldWindowButtonUpFcn);
set(thisFig,'WindowButtonMotionFcn',...
    gui.moveitData.oldWindowButtonMotionFcn);

% Restore pointer shape
set(thisFig,'Pointer','arrow');

drawnow;



