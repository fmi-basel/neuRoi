function offsetyx = alignImagePR(templateImg,inputImg,debug)
% crossConv = fftshift(real(ifft2(conj(fft2(inputImg).* ...
%                                      fft2(templateImg)))));
    crossConv = fftshift(real(ifft2(conj(fft2(inputImg).* ...
                                         fft2(templateImg)))));
    [y,x] = find(crossConv==max(crossConv(:))); % find the 255 peak
    autoConv =fftshift(real(ifft2(conj(fft2(templateImg).*fft2(templateImg)))));
    [y0,x0] = find(autoConv==max(autoConv(:))); %Find the 255 peak
    offsetyx =  [y-y0, x-x0];
    if exist('debug','var')
        if debug
            disp('yx')
            disp([y x])
            disp('y0x0')
            disp([y0 x0])

            figure('Name','crossConv')
            imagesc(crossConv)
            hold on
            plot(x,y,'*')
            hold off
            figure('Name','autoConv')
            imagesc(autoConv)
            hold on 
            plot(x0,y0,'o')
            hold off
        end
    end

    function xcorrComplex = fastCrossCorrelation2D(a,b)
        fa = fft2(a);
        fb = fft2(b);
        xcorrComplex = ifft2(conj(fa).*fb);
        
