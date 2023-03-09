function roiArray = convertMaskToRoiArray(mask)
    roiArray = RoiFreehand.empty();
    for j=1:max(max(mask))
        [col,row]=find(mask==j);
        if ~isempty(row)
            poly = roiFunc.mask2polyNew(mask==j);
            if length(poly) > 1
                % TODO If the mask corresponds multiple polygon,
                % for simplicity,
                % take the largest polygon
                warning(sprintf('ROI %d has multiple components, only taking the largest one.',j))
                pidx = find([poly.Length] == max([poly.Length]));
                poly = poly(pidx);
            end
            xposition=poly.X;
            yposition=poly.Y;
            position = [xposition,yposition];
            newroi = RoiFreehand(position);
            newroi.tag = j;
            roiArray(end+1) = newroi;
        else
            tempString=strcat("lost roi detected: roi number: " ,int2str(j)," in trial: ", int2str(i));
            disp(tempString);
        end
    end
    
end

