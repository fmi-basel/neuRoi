function offsetyx = alignImage(templateImg,inputImg)
    crossConv = fftshift(real(ifft2(conj(fft2(inputImg).*fft2(templateImg)))));
    [y,x] = find(crossConv==max(crossConv(:))); % find the 255 peak
    autoConv =fftshift(real(ifft2(conj(fft2(templateImg).*fft2(templateImg)))));
    [y0,x0] = find(autoConv==max(autoConv(:))); %Find the 255 peak
    offsetyx =  [y-y0, x-x0];
end
