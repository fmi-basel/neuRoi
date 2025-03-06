function [offsetYx,varargout] = alignImage(movingImg,fixedImg,fitGauss,normFlag,debug)
% ALIGNIMAGE Computes the translational offset between two images using cross-correlation.
%
% This function estimates the displacement required to align `movingImg` to 
% `fixedImg` by computing the cross-correlation in the Fourier domain. It can 
% optionally use Gaussian fitting for subpixel precision.
%
% The offsetYx means the number of pixels that the moving image should be shifted to align with the fixed image.
%
% Args:
%   movingImg (2D array): The image to be aligned (moving image).
%   fixedImg (2D array): The reference image (fixed image).
%   fitGauss (logical, optional): Whether to fit a Gaussian to the cross-correlation peak 
%       for subpixel accuracy. Default: `false`.
%   normFlag (logical, optional): If `true`, normalizes images before computing cross-correlation 
%       by subtracting the mean. Default: `false`.
%   debug (logical, optional): If `true`, enables debugging mode to visualize cross-correlation 
%       results and display key values. Default: `false`.
%
% Returns:
%   offsetYx (1x2 double): The estimated YX translation to align `movingImg` to `fixedImg`.
%       - `offsetYx(1)`: Vertical shift (Y displacement).
%       - `offsetYx(2)`: Horizontal shift (X displacement).
%
%   varargout (optional): If requested, returns an additional alignment error measure.
%       - `varargout{1}` (double): Estimated alignment error (if `normFlag` is enabled).
%
% Example:
%   movingImg = imread('trial1.tif');
%   fixedImg = imread('template.tif');
%   offset = alignImage(movingImg, fixedImg);
%   alignedImg = circshift(movingImg, offset);
%
% Author: Bo Hu 2021

% TODO IMPORTANT! change the code in align batch so that fitGauss
% was not used because of debugging...
    if ~exist('normFlag','var')
        normFlag = false;
    end
    
    if ~exist('fitGauss','var')
        fitGauss = false;
    end
    
    if ~exist('debug','var')
        debug = false;
    end
    
    if normFlag
        movingImg = movingImg - mean(movingImg(:));
        fixedImg = fixedImg - mean(fixedImg(:));
    end
    

    
    fa = fft2(movingImg);
    fb = fft2(fixedImg);
    crossCorrComplex = ifft2(conj(fa).*fb);
    % crossCorr = fftshift(real(crossCorrComplex));
    crossCorr = fftshift(abs(crossCorrComplex));
    if fitGauss
        [xx,yy] = meshgrid(1:size(movingImg,2),1:size(movingImg,1));
        [fitresult, zfit, fiterr, zerr, resnorm, rr] = ...
        helper.fmgaussfit(xx,yy,crossCorr);
        x = fitresult(5);
        y = fitresult(6);
    else
        [y,x] = find(crossCorr==max(crossCorr(:)));
    end
    
    yx0 = ceil((size(fixedImg)+1)/2); % center of image
    offsetYx =  [y-yx0(1), x-yx0(2)];
    
    if nargout == 2
        if fitGauss
            ccmax = fitresult(7) + fitresult(1);
        else
            ccmax = crossCorr(y,x);
        end
        
        if normFlag
            corrCoef= ccmax/std(movingImg(:))/std(fixedImg(:))/length(movingImg(:));
            err = 1.0 - abs(corrCoef);
        else
            % rg00 = sum(movingImg(:).^2);
            % rf00 = sum(fixedImg(:).^2);
            % err = 1.0 - ccmax.^2/(rg00*rf00);
            err = nan;
        end
        
        varargout{1} = err;
    end
    
    % The direction of offsetYx: moving(0) ~=~ fixed(offsetYx)
    
    if debug
        % One-line code for doing debugging in console
        % figure('Name','crossCorr');imagesc(crossCorr);hold on;plot(x,y,'*');figure('Name','Fitted Gauss');imagesc(zfit);hold on;plot(x,y,'*')
        % figure('Name','template');imagesc(fixedImg);figure('Name','input');imagesc(movingImg)
        disp('yx')
        disp([y x])
        disp('y0x0')
        disp(yx0)

        figure('Name','crossCorr')
        imagesc(crossCorr)
        hold on
        plot(x,y,'*')
        plot(yx0(2),yx0(1),'o')
        hold off
    end
        
