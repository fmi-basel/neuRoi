function corrVec = calcPatternCorrelation(timeTraceMat1, ...
                                               timeTraceMat2,sigma, ...
                                               debug)
if ~exist('sigma','var')
    sigma = 30;
end
corrMat = corr(timeTraceMat1,timeTraceMat2);
gaussFilter = fspecial('gaussian',[5 5],sigma);
corrMat = conv2(CorrMat,gaussFilter,'same');
corrVec = diag(corrMat);

