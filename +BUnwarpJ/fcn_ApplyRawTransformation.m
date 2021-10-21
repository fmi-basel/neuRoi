%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021

function [Outputimage]= fcn_ApplyRawTransformation(Image , transformationPath)


    %TO DO compare input size with transformation!

    [xcorr, ycorr, height, width]= fcn_LoadRawTransformation(transformationPath);
    
    %clipping max min values. rethink about this...this will messup the last
    %and first pixel. Does NAN helps?
    xcorr(xcorr>512)=512;
    xcorr(xcorr<1)=1;
    
    ycorr(ycorr>512)=512;
    ycorr(ycorr<1)=1;
    
    Outputimage = zeros(height, width);
    Outputimage= Image(sub2ind(size(Image),uint16(permute(ycorr,[2 1])),uint16(permute(xcorr,[2 1]))));
    

end