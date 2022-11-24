function result = isaRoiPatch(hobj)
    result = false;
    if ~isempty(hobj)
        if ishandle(hobj) && isvalid(hobj) && isprop(hobj,'Tag')
            tag = get(hobj,'Tag');
            if strfind(tag,'roi_')
                result = true;
            end
        end
    end
end
