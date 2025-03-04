function [subMovie,template] = subtractPreampRing(rawMovie,noSignalWindow)
% SUBTRACTPREAMPRING subtracts from a calcium imaging movie the
% striped pattern (bright dots in alternative lines) at the edge.
% Usage: subMovie = subtractPreampRing(rawMovie,noSignalWindow)
% noSignalWindow contains first and last number of frames that no
% signal from PMT is recorded.
template = mean(rawMovie(:,:,noSignalWindow(1):noSignalWindow(2)),3);
template_odd = mean(template(1:2:end,:),1);
template_even = mean(template(2:2:end,:),1);
for k = 1:size(template,1)/2
    template(2*k-1,:) = template_odd;
    template(2*k,:) = template_even;
end
dataType = class(rawMovie);

if strcmp(dataType, 'uint8')
    template = uint8(template);
elseif strcmp(dataType, 'uint16')
    template = uint16(template);
end

subMovie = rawMovie - template;
end
