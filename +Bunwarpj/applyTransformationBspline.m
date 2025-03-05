%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021

function [outImg]= applyTransformation(img, transform, offsetYx)
% TODO compare input size with transformation!
    if strcmp(transform.type, 'identity')
        outImg = img;
    elseif strcmp(transform.type, 'bunwarpj')
        sourceModel = Bunwarpj.BSplineModel(img);
        xcorr = transform.xcorr;
        ycorr = transform.ycorr;
        height = transform.imageSize(1);
        width = transform.imageSize(2);
        
        %clipping max min values. rethink about this...this will messup the last
        %and first pixel. Does NAN helps?
        %xcorr(xcorr>width)=width;
        %xcorr(xcorr<1)=1;
        
        %ycorr(ycorr>height)=height;
        %ycorr(ycorr<1)=1;
        
        imageSize = size(img);
        outImg = zeros(height, width);
        for v = 1:height
            for u = 1:width
                x = xcorr(v, u);
                y = ycorr(v, u);

                if x >= 1 && x <= width && y >= 1 && y <= height
                    % Use B-Spline interpolation from BSplineModel
                    outImg(v, u) = sourceModel.interpolateI(x, y);
                else
                    outImg(v, u) = 0;
                end
            end
        end

    else
        error(sprintf('Unknown transformation type %s', transform.type))
    end

    outImg = circshift(outImg, offsetYx);
end