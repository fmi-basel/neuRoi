function [outImg] = applyTransformation(img, transform)
    switch transform.type
        case 'identity'
            % No transformation
            outImg = img;
        case 'opticFlow'
            outImg = nrOpticFlow.core.compensate_sequence_uv(img, img, transform.flowField); %the second img argument is a place holder
        otherwise
            error("Unknown transformation type %s", transform.type);
    end
end
