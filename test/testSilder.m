fig = figure;
sld = uicontrol('Style','slider','Units','normal',...
                   'Position',[0.7 0.95 0.25 0.04],...
                   'Min',0,'Max',100,'Value',20);
% set(sld,'Callback',@(x,y) disp(x.Value));
addlistener(sld,'Value','PostSet',@(s,e) disp(e.AffectedObject.(s.Name)))



