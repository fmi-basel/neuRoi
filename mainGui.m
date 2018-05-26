function mainGui()
mainFig = figureDM('Position',[600,300,400,100]);
handles = {}
handles.copyRoiButton  = uicontrol('Style','pushbutton',...
                                   'String','copyRoi',...
                                   'Units','normal',...
                                   'Position',[0.2,0.1,0.3,0.5]);
handles.pasteRoiButton  = uicontrol('Style','pushbutton',...
                                   'String','pasteRoi',...
                                   'Units','normal',...
                                   'Position',[0.6,0.1,0.3,0.5]);


baseDir = '/home/hubo/Projects/juvenile_Ca_imaging/data/2018-05-24';
fileName1 = 'BH18_25dpf_f2_tel_zm_food_003_.tif';
filePath1 = fullfile(baseDir,fileName1);
handles.controller1 = openFile(filePath1);

fileName2 = 'BH18_25dpf_f2_tel_zm_ala_004_.tif';
filePath2 = fullfile(baseDir,fileName2);
handles.controller2 = openFile(filePath2);

setappdata(mainFig,'handles',handles)
end

function mycontroller = openFile(filePath)
    mymodel = NrModel(filePath);
    mycontroller = NrController(mymodel);
end

function copyRoi_Callback(source,event)
    mainFig = source.Parent
    handles = getappdata(mainFig,'handles')
    copiedRoi = handles.controller1.copyRoi()
    setappdata(mainFig,'copiedRoi',copiedRoi)
    display(getappdata(mainFig,'copiedRoi'))
        
    
    


