function [alignResult,varargout] = alignTrials(inDir,inFileList,templateName,varargin)
% ALIGNTRIALS Align each trial image to a reference (template) anatomy image.
%
% This function loads a series of anatomical images (trials) from a directory,
% aligns each trial to a given template image, and computes the necessary
% translations to match the template.
%
% The YX shift means the number of pixels to shift the trial image in the Y and X to match the template.
%
% Args:
%   inDir (char): Directory containing the trial images.
%   inFileList (cell array of char): List of filenames to be aligned.
%   templateName (char): Filename of the template anatomy image.
%
%   Name-Value Parameters:
%       'outFilePath' (char, default ''): Path to save the alignment result.
%       'stackFilePath' (char, default ''): Path to save the aligned image stack.
%       'plotFig' (logical, default false): Whether to visualize the alignment results.
%       'climit' (1x2 double, default [0 1]): Contrast limits for image display.
%       'debug' (logical, default false): Whether to enable debug mode (verbose output).
%
% Returns:
%   alignResult (struct): Structure containing alignment information:
%       - inDir (char): Input directory.
%       - inFileList (cell array of char): List of aligned files.
%       - templateName (char): Template filename.
%       - offsetYxMat (nFile x 2 double): YX shift matrix for each image.
%
%   varargout (optional): If requested, returns the aligned image stack.
%
% Example:
%   inDir = 'data/images';
%   inFileList = {'trial1.tif', 'trial2.tif'};
%   templateName = 'template.tif';
%   alignResult = alignTrials(inDir, inFileList, templateName, 'plotFig', true);
%
%   % Save the aligned stack
%   [alignResult, alignedStack] = alignTrials(inDir, inFileList, templateName, ...
%                                             'stackFilePath', 'alignedStack.tif');
%
% Author: Bo Hu 2021


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
