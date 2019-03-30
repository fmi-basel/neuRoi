function regResult = alignTrials(anatomyDir,anatomyNameArray,templateInd,outFilePath,plotFig,climit)
% ALIGNTRIALS align each trial with respect to the template anatomy
% image
%     Args:
%     Returns:
if nargin < 4
    outDir = '';
    plotFig = false;
    climit = [];
elseif nargin < 5
    plotFig = false;
    climit = [];
end

nFile = length(anatomyNameArray);
anatomyArray = batch.loadStack(anatomyDir, anatomyNameArray);
templateAna = anatomyArray(:,:,templateInd);
offsetYxMat = zeros(nFile,2);

for k=1:nFile
    offsetYx = movieFunc.alignImage(anatomyArray(:,:,k),templateAna);
                          
    offsetYxMat(k,:) = offsetYx;
    if plotFig
        fig = figure;
        fig.Name = [num2str(k) ': ' anatomyNameArray{k}];
        newAna = movieFunc.shiftImage(anatomyArray(:,:,k),offsetYx);
        tshow = imadjust(mat2gray(templateAna),climit);
        nshow = imadjust(mat2gray(newAna),climit);
        imshowpair(tshow,nshow,'Scaling','joint');
    end
end

% Save registration result
if length(outFilePath)
    regResult.dataDir = anatomyDir;
    regResult.anatomyNameArray = anatomyNameArray;
    regResult.templateInd = templateInd;
    regResult.offsetYxMat = offsetYxMat;
    save(outFilePath,'regResult')
end




