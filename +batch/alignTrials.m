function alignResult = alignTrials(inDir,inFileList,templateName,outFilePath,plotFig,climit,debug)
% ALIGNTRIALS align each trial with respect to the template anatomy
% image
%     Args:
%     Returns:
if nargin < 4
    outFilePath = '';
    plotFig = false;
    climit = [];
    debug = false;
elseif nargin < 5
    plotFig = false;
    climit = [];
    debug = false;
elseif nargin < 7
    debug = false;
end

nFile = length(inFileList);
anatomyArray = batch.loadStack(inDir,inFileList);

templateDir = fileparts(templateName);
if isempty(templateDir)
    templatePath = fullfile(inDir,templateName);
else
    templatePath = templateName;
end
templateAna = movieFunc.readTiff(templatePath);

offsetYxMat = zeros(nFile,2);

for k=1:nFile
    offsetYx = movieFunc.alignImage(anatomyArray(:,:,k),templateAna,debug);
                          
    offsetYxMat(k,:) = offsetYx;
    if plotFig
        fig = figure;
        fig.Name = [num2str(k) ': ' inFileList{k}];
        newAna = movieFunc.shiftImage(anatomyArray(:,:,k),offsetYx);
        tshow = imadjust(mat2gray(templateAna),climit);
        nshow = imadjust(mat2gray(newAna),climit);
        imshowpair(tshow,nshow,'Scaling','joint');
    end
end

alignResult.inDir = inDir;
alignResult.inFileList = inFileList;
alignResult.templateName = templateName;
alignResult.offsetYxMat = offsetYxMat;

% Save alignment result
if length(outFilePath)
    save(outFilePath,'alignResult')
end
