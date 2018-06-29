% Documented: we need to get the modifier data in two different
% manners
%% haha
set(gcf, 'WindowButtonDownFcn', @(h,e) disp(get(gcf,'SelectionType'))); ...
% mouse clicks: displays a single string: 'normal','alt','extend' or 'open'
%% heihei
set(gcf, 'WindowKeyPressFcn',   @(h,e) disp(e.Modifier));  % keyboard clicks: displays a cell-array of strings, e.g. {'shift','control','alt'}
