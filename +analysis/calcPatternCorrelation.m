function [corrVec,varargout] = calcPatternCorrelation(timeTraceMat1, ...
                                               timeTraceMat2,sigma, ...
                                               debug)
if ~exist('sigma','var')
    sigma = 0;
end
corrMat = corr(timeTraceMat1,timeTraceMat2);
if sigma
    disp('Smoothing the corrMat')
    gaussFilter = fspecial('gaussian',[5 5],sigma);
    corrMat = conv2(corrMat,gaussFilter,'same');
end
corrVec = diag(corrMat);
if nargout == 2
    varargout{1} = corrMat;
end
