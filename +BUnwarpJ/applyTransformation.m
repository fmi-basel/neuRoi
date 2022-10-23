%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021

function [Outputimage]= applyTransformation(Image , transformFile)


%TO DO compare input size with transformation!
    transform = load(transformFile);
    xcorr = transform.xcorr;
    ycorr = transform.ycorr;
    height = transform.height;
    width = transform.width;
    
    %clipping max min values. rethink about this...this will messup the last
    %and first pixel. Does NAN helps?
    xcorr(xcorr>width)=width;
    xcorr(xcorr<1)=1;
    
    ycorr(ycorr>height)=height;
    ycorr(ycorr<1)=1;
    
    Outputimage = zeros(width,height);
    Imagesize=size(Image);
    Outputimage= Image(sub2ind([Imagesize(1) Imagesize(2)],uint16(permute(ycorr,[2 1])),uint16(permute(xcorr,[2 1]))));
    

end
