function hfig = neuRoiGui(varargin)
% NEUROIGUI creates a gui for drawing ROI on two-phonton imaging
% movies.

    handles = {};
    for i = 1:2:length(varargin)
        switch varargin{1}
          case 'controller'
            handles.controller = varargin{i+1};
          otherwise
            error('unknown input')
        end
    end

    if ~(isfield(handles,'controller') & isa(handles.controller,'NrController'))
        error(['Please specify the controller for the neuRoiGui!\n Usage: ' ...
               'neuRoiGui(''controller'',hcontroller)'])
    end

    hfig = figureDM('Position',[500,300,600,500]); % figureDM is a
                                                % function to
                                                % create figure on dual monitor by Jan
    hfig.Name = 'My Window';
    handles.mapAxes = axes('Position',[0.2,0.1,0.7,0.7]);

    handles.anatomyButton  = uicontrol('Style','pushbutton',...
                               'String','Anatomy',...
                               'Units','normal',...
                               'Position',[0.2,0.8,0.1,0.08],...
                               'Callback',@(hobj,event)...
                               anatomy_Callback(hobj,event,handles));
    
    handles.responseButton  = uicontrol('Style','pushbutton',...
                               'String','dF/F',...
                               'Units','normal',...
                               'Position',[0.3,0.8,0.1,0.08],...
                               'Callback',@(hobj,event)...
                               response_Callback(hobj,event,handles));
    
    % handles.addRoiButton  = uicontrol('Style','togglebutton',...
    %                           'String','Add ROI',...
    %                           'Units','normal',...
    %                           'Position',[0.05,0.7,0.1,0.08],...
    %                           'Callback',@(hobj,event)...
    %                            addRoi_Callback(hobj,event,handles));
        

    guidata(hfig,handles)

    % Callback functions
    function anatomy_Callback(hObject, eventdata, handles)
    % hObject    handle to anatomy (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        handles.controller.setDisplayState('anatomy');
    end
    
    function response_Callback(hObject, eventdata, handles)
        handles.controller.setDisplayState('response');
    end
    
    function addRoi_Callback(hObject, eventdata, handles)
        handles.controller.addRoiToggle(hObject);
    end
    

    


end
