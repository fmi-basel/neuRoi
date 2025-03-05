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


function applyRawTransformationToSource(sourceImg, targetImg, source, transformation_x, transformation_y)
    % Get dimensions of target and source images
    [targetHeight, targetWidth] = size(targetImg);
    [sourceHeight, sourceWidth] = size(sourceImg);

    ORIGINAL = false; % Equivalent of Java boolean flag (not used in MATLAB)

    % Check if the source image is grayscale
    if numel(size(sourceImg)) == 2  % Grayscale image
        % Start source pyramids (if applicable in MATLAB)
        % This step is omitted because MATLAB does not require explicit threading
        
        % Initialize transformed image
        transformedImg = zeros(targetHeight, targetWidth);

        for v = 1:targetHeight
            for u = 1:targetWidth
                x = transformation_x(v, u);
                y = transformation_y(v, u);

                if x >= 1 && x <= sourceWidth && y >= 1 && y <= sourceHeight
                    % Interpolation (using MATLAB’s built-in interp2 function)
                    transformedImg(v, u) = interp2(double(sourceImg), x, y, 'linear', 0);
                else
                    transformedImg(v, u) = 0;
                end
            end
        end

        % Normalize and display result
        transformedImg = mat2gray(transformedImg); % Normalize to [0,1]
        figure, imshow(transformedImg), title('Transformed Image');
    end
end
