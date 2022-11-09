function [offsetYx,varargout] = alignImage(movingImg,fixedImg,fitGauss,normFlag,debug)
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
        
