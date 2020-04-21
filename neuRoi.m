function neuRoi()
welcHdl = welcomeGui();
welcHdl.openButton.Callback = @openButton_Callback;

% Initialize with an empty experiment

function openButton_Callback(source,event)
defaultDir = '/home/hubo/Projects/Ca_imaging/results/2020-01-15-longPulse/Dp'
[fileName,fileDir] = uigetfile('*.mat','Open Experiment',defaultDir);
filePath = fullfile(fileDir,fileName)
foo = load(filePath);
hNr = foo.myexp;
hNrCtrl = NrController(hNr);
assignin('base','hNr',hNr);
assignin('base','hNrCtrl',hNrCtrl);
% myexp = empty 
% mycon = NrController(myexp);

function newButton_Callback(source,event)
hNr = NrModel();
hNrCtrl = NrController(hNr);
assignin('base','hNr',hNr);
assignin('base','hNrCtrl',hNrCtrl);
