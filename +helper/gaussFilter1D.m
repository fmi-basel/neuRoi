function filteredSignal = gaussFilter1D(signal,M,alpha,dim)
if ~exist('dim','var')
    dim = 1;
end
gaussianWindow = gausswin(M,alpha);
gaussianWindow = gaussianWindow/sum(gaussianWindow);
filteredSignal = filter(gaussianWindow,1,signal,[],dim);
% TODO shift back the signal
