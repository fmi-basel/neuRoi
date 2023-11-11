function roi = convertRoiFreehandToRoiM(roiFh, imageSize)
    roiMask = roiFh.createMask(imageSize);
    [mposY,mposX] = find(roiMask);
    position = [mposX,mposY];
    roi = roiFunc.RoiM('position', position,...
                       'tag', roiFh.tag);
end

