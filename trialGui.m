function handles = trialGui(varargin)
% TRIALGUI creates a gui for drawing ROI on two-phonton imaging
% movies.
    if nargin > 1
        error('Usage: neuRoiGui([mapSize]');
    elseif nargin == 1
        mapSize = varargin{1};
    else
        mapSize = [10,10];
    end

    handles.mainFig = figure('Position',[600,300,750,650]);
    deleteDefaultFigureMenu(handles.mainFig);
    
    handles.fileMenu = uimenu(handles.mainFig,'Text','File');
    handles.saveRoiMenu = uimenu(handles.fileMenu,'Text',....
                                 'Save ROIs','Accelerator','S');
    handles.loadRoiMenu = uimenu(handles.fileMenu,'Text',...
                                 'Load ROIs');
    
    handles.metaText = uicontrol('Style','text',...
                                 'String','meta data',...
                                 'Units','normal',...
                                 'Position',[0.02 0.85 0.12 0.15],...
                                 'BackgroundColor',[255,250,250]/255);
    
    handles.mapAxes = axes('Position',[0.15 0.1 0.8 0.72]);
    handles.mapImage  = imagesc(zeros(mapSize),'Parent',handles.mapAxes);
    
    handles.mapOptionText = uicontrol('Style','text',...
                                      'String','map option',...
                                      'Units','normal',...
                                      'Position',[0.15 0.85 0.6 0.05],...
                                      'BackgroundColor',[255,250,250]/255);
    
    handles.mapButtonGroup= uibuttongroup('Position',[0.15,0.91,0.30,0.05]);
    nMapButton = 6;
    mb = {};
    for i=1:nMapButton
        mb{1} = createMapButton(handles.mapButtonGroup,i);
    end
    
    % Sync time trace checkbox
    handles.syncTraceCheckbox = uicontrol('Style','checkbox',...
                                     'String','sync time trace',...
                                          'Units','normal',...
                                          'Position',[0.5, 0.9, 0.2, 0.1]);
    
    % Sliders for contrast adjustment
    handles.contrastSliderGroup = uibuttongroup('Position',[0.7,0.9,0.25,0.1]);
    handles.contrastMinSlider = uicontrol(handles.contrastSliderGroup,...
                                          'Style','slider', ...
                                          'Tag','contrastSlider_1',...
                                          'Units','normal',...
                                          'Position',[0 0.5 1 0.4]);
    
    handles.contrastMaxSlider = uicontrol(handles.contrastSliderGroup,...
                                          'Style','slider', ...
                                          'Tag','contrastSlider_2',...
                                          'Units','normal',...
                                          'Position',[0 0 1 0.4]);
    
    % UIContextMenu for ROI
    handles.roiMenu = uicontextmenu(handles.mainFig);
    handles.roiMenuEntry1 = uimenu(handles.roiMenu,'Label','Move ROI(s)');

    % Group for displaying ROI
    handles.roiGroup = hggroup(handles.mapAxes,'Tag','roiGroup');
    
    
    handles.traceFig = figure('Name','Time Trace','Tag','traceFig',...
                              'Position',[1350,500,500,400],'Visible','off');
    handles.traceAxes = axes();
    xlabel(handles.traceAxes,'Time (s)')
    ylabel(handles.traceAxes,'dF/F')
    figure(handles.mainFig)
    

function button = createMapButton(buttonGroup,ind)
    position = [0.15*(ind-1),0,0.15,1];
    tag = sprintf('mapButton_%d',ind);
    button = uicontrol(buttonGroup,...
                       'Style','togglebutton',...
                       'Tag',tag,...
                       'String',num2str(ind),...
                       'Units','normal',...
                       'Position',position);

function deleteDefaultFigureMenu(fig)
    set(0,'showhiddenhandles','on')
    tagArray = {'figMenuHelp','figMenuWindow','figMenuDesktop','figMenuTools',...
'figMenuInsert','figMenuView','figMenuEdit','figMenuFile'};
    for k=1:length(tagArray)
        tag = tagArray{k};
        hobj = findobj(fig,'Tag',tag);
        delete(hobj)
    end
    set(0,'showhiddenhandles','off')

