function [outImg] = applyTransformation(img, transform, interpolation_method)
    if nargin < 3
        interpolation_method = 'cubic';
    end

    switch transform.type
        case 'identity'
            % No transformation
            outImg = img;
        case 'opticFlow'
            outImg = nrOpticFlow.core.compensate_sequence_uv(img, img, transform.flowField, interpolation_method); %the second img argument is a place holder
        otherwise
            error("Unknown transformation type %s", transform.type);
    end

    % Make the datatype of outImg the same as the input image
    outImg = cast(outImg, class(img));
end
