function result = isaRoiPatch(hobj)
result = false;
if ishandle(hobj) && isvalid(hobj) && isprop(hobj,'Tag')
    tag = get(hobj,'Tag');
    if strfind(tag,'roi_')
        result = true;
    end
end
