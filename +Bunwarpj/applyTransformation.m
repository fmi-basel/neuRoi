%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021

function [outImg]= applyTransformation(img, transform, offsetYx)
% TODO compare input size with transformation!
    if strcmp(transform.type, 'identity')
        outImg = img;
    elseif strcmp(transform.type, 'bunwarpj')
        xcorr = transform.xcorr;
        ycorr = transform.ycorr;
        height = transform.imageSize(1);
        width = transform.imageSize(2);
        
        %clipping max min values. rethink about this...this will messup the last
        %and first pixel. Does NAN helps?
        xcorr(xcorr>width)=width;
        xcorr(xcorr<1)=1;
        
        ycorr(ycorr>height)=height;
        ycorr(ycorr<1)=1;
        
        imageSize = size(img);
        outImg = img(sub2ind(imageSize, uint16(ycorr), uint16(xcorr)));
    else
        error(sprintf('Unknown transformation type %s', transform.type))
    end

    outImg = circshift(outImg, offsetYx);
end
