function offsetYx = alignImage(movingImg,fixedImg,debug)
    crossCorrComplex = fastCrossCorrelation2D(movingImg,fixedImg);
    crossCorr = fftshift(real(crossCorrComplex));
    [y,x] = find(crossCorr==max(crossCorr(:)));
    yx0 = ceil((size(fixedImg)+1)/2); % center of image
    offsetYx =  [y-yx0(1), x-yx0(2)];
    % moving(0) ~=~ fixed(offsetYx)
    
    if exist('debug','var')
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
    end

    function xcorrComplex = fastCrossCorrelation2D(a,b)
        fa = fft2(a);
        fb = fft2(b);
        xcorrComplex = ifft2(conj(fa).*fb);
        
