function P =mask2poly(mask)
    
    BW3 = imresize(mask,3,'method','nearest');
    B3 = bwboundaries(BW3);
    B3 = B3{1};

    P.X = (B3(:,2) + 1)/3;
    P.Y = (B3(:,1) + 1)/3;

    P.Length=length(P.X);
    P.Fill=1;

end