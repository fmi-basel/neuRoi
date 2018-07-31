function handles = neuRoiGui(varargin)
% NEUROIGUI creates a gui for drawing ROI on two-phonton imaging
% movies.
    if nargin > 1
        error('Usage: neuRoiGui([mapSize]');
    elseif nargin == 1
        mapSize = varargin{1};
    else
        mapSize = [10,10];
    end

    handles = {};

    handles.mainFig = figureDM('Position',[600,300,750,650]); % figureDM is a
                                                % function to
                                                % create figure on dual monitor by Jan
    handles.mapAxes = axes('Position',[0.15 0.1 0.8 0.72]);
    handles.mapImage  = imagesc(zeros(mapSize),'Parent',handles.mapAxes);
    
    handles.mapOptionText = uicontrol('Style','text',...
                                      'String','xxxxx',...
                                      'Units','normal',...
                                      'Position',[0.15 0.85 0.6 0.05],...
                                      'BackgroundColor',[255,250,250]/255);
    
    handles.mapButtonGroup= uibuttongroup('Position',[0.15,0.91,0.30,0.05]);
    nMapButton = 6;
    mb = {};
    for i=1:nMapButton
        mb{1} = createMapButton(handles.mapButtonGroup,i);
    end
    
    handles.addRoiButton  = uicontrol('Style','togglebutton',...
                              'String','Add ROI',...
                              'Units','normal',...
                              'Position',[0.02,0.8,0.1,0.08]);
    
    % Sliders for contrast adjustment
    handles.contrastMinSlider = uicontrol('Style','slider', ...
                                          'Units','normal','Position',[0.7 0.95 0.25 0.04]);
    
    handles.contrastMaxSlider = uicontrol('Style','slider', ...
                                          'Units','normal','Position',[0.7 0.9 0.25 0.04]);
    
    
    handles.traceFig = figureDM('Name','Time Trace','Tag','traceFig',...
                                'Position',[50,500,500,400],'Visible','off');
    handles.traceAxes = axes();
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
    
