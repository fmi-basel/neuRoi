function hfig = neuRoiGui(varargin)
% NEUROIGUI creates a gui for drawing ROI on two-phonton imaging
% movies.

    handles = {};

    hfig = figureDM('Position',[500,300,900,700]); % figureDM is a
                                                % function to
                                                % create figure on dual monitor by Jan
    hfig.Name = 'My Window';
    handles.mapAxes = axes('Position',[0.2,0.1,0.7,0.7]);

    handles.anatomyButton  = uicontrol('Style','pushbutton',...
                               'String','Anatomy',...
                               'Units','normal',...
                               'Position',[0.2,0.8,0.1,0.08]);
    
    handles.responseButton  = uicontrol('Style','pushbutton',...
                               'String','dF/F',...
                               'Units','normal',...
                               'Position',[0.3,0.8,0.1,0.08]);
    
    handles.addRoiButton  = uicontrol('Style','togglebutton',...
                              'String','Add ROI',...
                              'Units','normal',...
                              'Position',[0.05,0.7,0.1,0.08]);

    guidata(hfig,handles)
    
end
