function handles = neuRoiGui()
handles.mainFig= figure('Position',[600,300,600,200]);
set(handles.mainFig,'MenuBar','none');
set(handles.mainFig,'ToolBar','none');
set(handles.mainFig,'Name','neuRoi','NumberTitle','off');

handles.fileListBox = uicontrol(handles.mainFig,'Style','listbox','Unit', ...
                                'normal','Position',[0.1,0.1,0.3,0.8]);
