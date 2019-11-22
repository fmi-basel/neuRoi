function offsetYx = alignImage(movingImg,fixedImg,fitGauss,debug)
% TODO IMPORTANT! change the code in align batch so that fitGauss
% was not used because of debugging...
    if ~exist('fitGauss','var')
        fitGauss = false;
    end
    
    if ~exist('debug','var')
        debug = false;
    end
    
    crossCorrComplex = fastCrossCorrelation2D(movingImg,fixedImg);
    crossCorr = fftshift(real(crossCorrComplex));
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
    
    % moving(0) ~=~ fixed(offsetYx)
    
    if debug
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

    function xcorrComplex = fastCrossCorrelation2D(a,b)
        fa = fft2(a);
        fb = fft2(b);
        xcorrComplex = ifft2(conj(fa).*fb);
        
