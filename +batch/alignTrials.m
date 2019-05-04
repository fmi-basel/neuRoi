function [alignResult,varargout] = alignTrials(inDir,inFileList,templateName,varargin)
% ALIGNTRIALS align each trial with respect to the template anatomy
% image
%     Args:
%     Returns:

pa = inputParser;
addRequired(pa,'inDir',@ischar);
addRequired(pa,'inFileList',@iscell);
addRequired(pa,'templateName',@ischar);
addParameter(pa,'outFilePath','',@ischar);
addParameter(pa,'stackFilePath','',@ischar);
addParameter(pa,'plotFig',false);
addParameter(pa,'climit',[0 1]);
addParameter(pa,'debug',false);
parse(pa,inDir,inFileList,templateName,varargin{:})
pr = pa.Results;


nFile = length(pr.inFileList);
anatomyArray = batch.loadStack(pr.inDir,pr.inFileList);

templateDir = fileparts(pr.templateName);
if isempty(templateDir)
    templatePath = fullfile(pr.inDir,pr.templateName);
else
    templatePath = pr.templateName;
end
templateAna = movieFunc.readTiff(templatePath);

offsetYxMat = zeros(nFile,2);

for k=1:nFile
    offsetYx = movieFunc.alignImage(anatomyArray(:,:,k),templateAna,pr.debug);
                          
    offsetYxMat(k,:) = offsetYx;
    if pr.plotFig
        fig = figure;
        fig.Name = [num2str(k) ': ' pr.inFileList{k}];
        newAna = movieFunc.shiftImage(anatomyArray(:,:,k),offsetYx);
        tshow = imadjust(mat2gray(templateAna),pr.climit);
        nshow = imadjust(mat2gray(newAna),pr.climit);
        imshowpair(tshow,nshow,'Scaling','joint');
    end
end

alignResult.inDir = pr.inDir;
alignResult.inFileList = pr.inFileList;
alignResult.templateName = pr.templateName;
alignResult.offsetYxMat = offsetYxMat;

% Save alignment result
if length(pr.outFilePath)
    save(pr.outFilePath,'alignResult')
end

if nargout == 2 | length(pr.stackFilePath)
    alignedStack = shiftStack(anatomyArray,offsetYxMat);
    if length(pr.stackFilePath)
        movieFunc.saveTiff(alignedStack, ...
                           pr.stackFilePath);
    end
    if nargout == 2
        varargout{1} = alignedStack;
    end
end

function alignedStack = shiftStack(stack,offsetYxMat)
alignedStack = stack;
for k=1:size(stack,3)
    yxShift = offsetYxMat(k,:);
    alignedStack(:,:,k) = circshift(alignedStack(:,:,k),yxShift);
end
