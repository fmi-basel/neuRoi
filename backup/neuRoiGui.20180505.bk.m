function varargout = neuRoiGui.20180505.bk(varargin)
% NEUROIGUI MATLAB code for neuRoiGui.fig
%      NEUROIGUI, by itself, creates a new NEUROIGUI or raises the existing
%      singleton*.
%
%      H = NEUROIGUI returns the handle to a new NEUROIGUI or the handle to
%      the existing singleton*.
%
%      NEUROIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEUROIGUI.M with the given input arguments.
%
%      NEUROIGUI('Property','Value',...) creates a new NEUROIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before neuRoiGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to neuRoiGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help neuRoiGui

% Last Modified by GUIDE v2.5 04-May-2018 18:11:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @neuRoiGui_OpeningFcn, ...
                   'gui_OutputFcn',  @neuRoiGui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before neuRoiGui is made visible.
function neuRoiGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to neuRoiGui (see VARARGIN)

% Choose default command line output for neuRoiGui
handles.output = hObject;

% Bo Hu 2018-05-04
% get handle to the controller
for i = 1:2:length(varargin)
    switch varargin{1}
      case 'controller'
        handles.controller = varargin{i+1}
      otherwise
        error('unknown input')
    end
end


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes neuRoiGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = neuRoiGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in anatomy.
function anatomy_Callback(hObject, eventdata, handles)
% hObject    handle to anatomy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.controller.setDisplayState('anatomy')


% --- Executes on button press in response.
function response_Callback(hObject, eventdata, handles)
% hObject    handle to response (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.controller.setDisplayState('response')


% --- Executes on button press in masterResponse.
function masterResponse_Callback(hObject, eventdata, handles)
% hObject    handle to masterResponse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.controller.setDisplayState('masterResponse')


% --- Executes on button press in localCorr.
function localCorr_Callback(hObject, eventdata, handles)
% hObject    handle to localCorr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles.controller.setDisplayState('localCorr')


% --- Executes on button press in addRoi.
function addRoi_Callback(hObject, eventdata, handles)
% hObject    handle to addRoi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of addRoi
