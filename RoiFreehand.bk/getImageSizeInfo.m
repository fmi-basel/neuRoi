function imageInfo = getImageSizeInfo(hImg)
[xdata,ydata,cdata] = getimage(hImg);
imageSize = size(cdata);
imageInfo.xdata = xdata;
imageInfo.ydata = ydata;
imageInfo.imageSize = imageSize;

