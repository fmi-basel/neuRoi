function filteredSignal = gaussFilter1D(originalSignal,M,alpha)
gaussianWindow = gausswin(M,alpha);
if length(size(originalSignal)) == 1
    filteredSignal = conv(originalSignal, gaussianWindow);
else
    oriSize = size(originalSignal);
    filteredSignal = zeros(oriSize(1),oriSize(2)+M-1);
    for k=1:size(originalSignal,1)
        filteredSignal(k,:) = conv(originalSignal(k,:), ...
                                   gaussianWindow);
    end
end
