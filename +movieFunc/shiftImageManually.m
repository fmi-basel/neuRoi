function handles = shiftImageManually(movingImg,fixedImg,climit)
shiftLim = [-20 20];
fig = figure;

if exist('climit')
    gdt.fixedImg = imadjust(mat2gray(fixedImg),climit);
    gdt.movingImg = imadjust(mat2gray(movingImg),climit);
else
    gdt.fixedImg = fixedImg;
    gdt.movingImg = movingImg;
end
gdt.shiftXy = [0 0];
gdt.handles.imgAxes = axes('Position',[0.15 0.3 0.7 0.68]);
handles.imgAxes = gdt.handles.imgAxes;
% imshowpair(fixedImg, movingImg,'Scaling','joint','Parent',gdt.handles.imgAxes);
imshowpair(gdt.fixedImg, gdt.movingImg,'Scaling','joint','Parent',gdt.handles.imgAxes);

xText = uicontrol(fig,'Style','text',...
                  'String','X',...
                  'Unit','normal',...
                  'Position',[0.03 0.2 0.05 0.05]);
yText = uicontrol(fig,'Style','text',...
                  'String','Y',...
                  'Unit','normal',...
                  'Position',[0.03 0.1 0.05 0.05]);
xSlider = uicontrol(fig,'Style','slider',...
                    'Tag','xSlider',...
                    'Min',shiftLim(1),...
                    'Max',shiftLim(2),...
                    'Unit','normal',...
                    'Position',[0.1 0.2 0.4 0.05]);
ySlider = uicontrol(fig,'Style','slider',...
                    'Tag','ySlider',...
                    'Min',shiftLim(1),...
                    'Max',shiftLim(2),...
                    'Unit','normal',...
                    'Position',[0.1 0.1 0.4 0.05]);

set(xSlider,'Callback',@shiftImage_Callback);
set(ySlider,'Callback',@shiftImage_Callback);
guidata(fig,gdt);
handles.xSlider = xSlider;
handles.ySlider = ySlider;

function shiftImage_Callback(src,evnt)
gdt = guidata(src);
shiftXy = gdt.shiftXy;
switch src.Tag
  case 'xSlider'
    shiftXy(1) = src.Value;
  case 'ySlider'
    shiftXy(2) = src.Value;
end
newImg = imtranslate(gdt.movingImg,shiftXy);
imshowpair(gdt.fixedImg, newImg,'Scaling','joint','Parent',gdt.handles.imgAxes);
gdt.shiftXy = shiftXy;
guidata(src,gdt);
