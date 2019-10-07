function mainFig = mainGui()
mainFig = figureDM('Position',[100,300,400,100]);
handles = {};
handles.copyRoiButton  = uicontrol('Style','pushbutton',...
                                   'String','copyRoi',...
                                   'Units','normal',...
                                   'Position',[0.2,0.1,0.3,0.5]);
handles.pasteRoiButton  = uicontrol('Style','pushbutton',...
                                   'String','pasteRoi',...
                                   'Units','normal',...
                                   'Position',[0.8,0.1,0.3,0.5]);

handles.copyAllRoiButton  = uicontrol('Style','pushbutton',...
                                   'String','copyAllRoi',...
                                   'Units','normal',...
                                   'Position',[0.5,0.1,0.3,0.5]);

set(handles.copyRoiButton,'Callback', @copyRoi_Callback);
set(handles.pasteRoiButton,'Callback', @pasteRoi_Callback);

set(handles.copyAllRoiButton,'Callback', @copyAllRoi_Callback);

baseDir = '/home/hubo/Projects/Ca_imaging/data/2018-05-24';
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
    mainFig = source.Parent;
    handles = getappdata(mainFig,'handles');
    copiedRoi = handles.controller1.copyRoi();
    setappdata(mainFig,'roiClipboard',{copiedRoi});
    display(getappdata(mainFig,'roiClipboard'));
end

function pasteRoi_Callback(source,event)
    mainFig = source.Parent;
    handles = getappdata(mainFig,'handles');
    
    roiClipboard = getappdata(mainFig,'roiClipboard');
    mainFig2 = handles.controller2.view.guiHandles.mainFig;
    set(0, 'currentfigure', mainFig2);
    handles.controller2.addRoiArray(roiClipboard);
end

function copyAllRoi_Callback(source,event)
    mainFig = source.Parent;
    handles = getappdata(mainFig,'handles');
    roiClipboard = handles.controller1.copyRoiArray();
    setappdata(mainFig,'roiClipboard',roiClipboard);
    display(getappdata(mainFig,'roiClipboard'));
end


    
    


