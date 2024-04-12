function varargout = incrementdecrement(lblhdl, cfg, varargin)
%INCREMENTDECREMENT create a button group for incrementing/decrementing a value.
%   INCREMENTDECREMENT is a custom button group that simplifies the creation of
%   the "inc/dec" arrows that are commonly used in GUIs.
%
%   The "ButtonWidth" property can be customized, making the buttons any width
%   the user likes. By default, they are always the same as the button height,
%   making the buttons nice squares. The button height is always the same as the
%   height of the uicontrol edit box.
%
%   The "ButtonSide" propery can be customized as well, making the buttons
%   appear to either the left or the right side of the uicontrol. The default
%   value is 'left'.
%
%   INCREMENTDECREMENT(LBLHANDLE) creates the button group and associates it
%   with the uicontrol referenced by LBLHANDLE.
%
%   INCREMENTDECREMENT(LBLHANDLE, PARAM1, VAL1, PARAM2, ...) any number of
%   parameters can be passed in to configure the buttongroup properties.
%
%   GRP = INCREMENTDECREMENT(LBLHANDLE) returns the handle to the buttongroup.
%
%   There is no way to specify custom properties for the buttons themselves, but
%   you can always modify them after by doing:
%   >> lbl = uicontrol('Style','edit');
%   >> grp = incrementdecrement(lbl);
%   >> btns = get(grp,'Children');
%   The first child is the top (increment) button and the second is the bottom
%   (decrement) button.
%
%   Example
%   >> lbl = uicontrol('Style','edit');
%   >> grp = incrementdecrement(lbl);
%   Creates the edit box and associates the inc/dec buttons with it on the left.
%
%   >> lbl = uicontrol('Style','edit');
%   >> grp = incrementdecrement(lbl,'ButtonWidth',30,'ButtonSide','right');
%   Places very wide buttons on the right side, instead of the left.
%
%   >> lbl = uicontrol('Style','edit','Position',[50 50 80 80]);
%   >> grp = incrementdecrement(lbl);
%   Creates buttons that are much taller and wider than in example 1.
%
%   >> btns = get(grp,'Children');
%   >> set(btns(1),'BackgroundColor',[1 0 0]);
%   Turns the increment button red, leaving decrement unchanged.
%
%   See also uicontrol

% Author: Chad S Gilbert
% See attached license (BSD).

% Set default configurations.
if ~exist('cfg','var')
    cfg.ButtonSide = 'left';
    cfg.ButtonWidth = 'half';
    cfg.Position = 'default';
    cfg.Range = [-inf,inf];
end

% Read any config options meant for this fucntion.
ii = 1;
while ii < length(varargin)
    if isfield(cfg,varargin{1})
        cfg.(varargin{ii}) = varargin{ii+1};
        varargin(ii:ii+1) = [];
    else
        ii = ii + 2;
    end
end

% Get sizing info for the buttons.
set(lblhdl,'Units', 'Points');
lblpos = get(lblhdl, 'Position');

% Decide where to locate the buttons.
btnpos(4) = lblpos(4)/2;
if ischar(cfg.ButtonWidth)
    btnpos(3) = btnpos(4);
else
    btnpos(3) = cfg.ButtonWidth;
end

switch cfg.ButtonSide
    case 'left'
        btnpos(1) = lblpos(1) - btnpos(3) - 1;
    case 'right'
        btnpos(1) = lblpos(1) + lblpos(3);
    otherwise
        error('CSG:invalidOption','Invalid option specified for "ButtonSide".');
end
btnpos(2) = lblpos(2);

% Get positions for "up" and "down" buttons.
if ischar(cfg.Position)
    cfg.Position = [btnpos(1) btnpos(2) btnpos(3) btnpos(4)*2];
end
posup = [0 btnpos(4) btnpos(3) btnpos(4)];
posdn = [0 0         btnpos(3) btnpos(4)];

% Create the button group, which will contain the inc/dec buttons.
grp = uibuttongroup(varargin{:});
set(grp, 'BorderType' , 'none');
set(grp, 'BorderWidth', 0);
set(grp, 'Units'      , 'Points');
set(grp, 'Position'   , cfg.Position);

% Create the buttons.
hup = uicontrol('Style', 'PushButton', 'Parent', grp);
hdn = uicontrol('Style', 'PushButton', 'Parent', grp);

% Resize the buttons to fill the group.
set(hup, 'Units', 'Points', 'Position', posup);
set(hdn, 'Units', 'Points', 'Position', posdn);

% From http://www.mathworks.com/matlabcentral/newsreader/view_thread/51230.
fontsiz = min(btnpos(3),btnpos(4))/1.5;
set(hup, 'String', '<html>&#x25B2;</html>', 'FontSize', fontsiz);
set(hdn, 'String', '<html>&#x25BC;</html>', 'FontSize', fontsiz);

% Initalize the counter.
if isempty(get(lblhdl,'String'))
    set(lblhdl,'String','0');
end
initstring = get(lblhdl, 'String');
initval = round(str2num(initstring));
set(grp, 'UserData', initval);


% Set the callbacks.
set(hup, 'Callback', @inc);
set(hdn, 'Callback', @dec);

if nargout == 1
    varargout{1} = grp;
end

% Define the callbacks.
    function inc(varargin)
        oldval = get(grp, 'UserData');
        val = oldval+1;
        if val <= cfg.Range(2)
            set(grp, 'UserData', val);
            set(lblhdl,'String', num2str(val));
        end
    end

    function dec(varargin)
        oldval = get(grp, 'UserData');
        val = oldval-1;
        if val >= cfg.Range(1)
            set(grp, 'UserData', val);
            set(lblhdl,'String', num2str(val));
        end
    end

end
