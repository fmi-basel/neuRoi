function [mapData,mapOption] = calcAnatomy(rawMovie,varargin)
    % Method to calculate anatomy map
    % Usage: anatomyMap = nrmodel.calcAnatomy([nFrameLimit])
    % nFrameLimit: 1x2 array of two integers that specify the
    % beginning and end number of frames used to calculate the
    % anatomy.
        if nargin == 1
            defaultNFrameLimit = [1 size(rawMovie,3)];
            nFrameLimit = defaultNFrameLimit;
            sigma = 0;
        elseif nargin == 2
            mopt = varargin{1};
            nFrameLimit = mopt.nFrameLimit;
            sigma = mopt.sigma;
        else
            error('Wrong usage!')
            help TrialModel.calcAnatomy
        end
        
        if ~(length(nFrameLimit) && nFrameLimit(2)>= ...
             nFrameLimit(1))
            error(['nFrameLimit should be an 1x2 integer array with ' ...
                   '2nd element bigger that the 1st one.']);
        end
        if nFrameLimit(1)<1 || nFrameLimit(2)>size(rawMovie,3)
            error(sprintf(['nFrameLimit [%d, %d] exceeded ' ...
                           'the frame number of the movie %d'],[nFrameLimit, size(rawMovie,3)]));
        end
        
        mapData = mean(rawMovie(:,:,nFrameLimit(1): ...
                                        nFrameLimit(2)),3);
        if sigma
            mapData = conv2(mapData,fspecial('gaussian',[3 3], sigma),'same');
            mapOption.sigma = sigma;
        end
        mapOption.nFrameLimit = nFrameLimit;
    end