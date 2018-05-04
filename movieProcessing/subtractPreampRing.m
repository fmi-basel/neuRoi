function subMovie = subtractPreampRing(rawMovie,nTemplateFrame)    
template_window = [1:nTemplateFrame]';
template = mean(rawMovie(:,:,template_window),3);
template_odd = mean(template(1:2:end,:),1);
template_even = mean(template(2:2:end,:),1);
for k = 1:size(template,1)/2
    template(2*k-1,:) = template_odd;
    template(2*k,:) = template_even;
end
subMovie = rawMovie - uint16(template);
end
