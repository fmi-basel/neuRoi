function dftemplate = dftemplateSetupC(rawMovie, skippingNumber, gaussianBlur )
    

    
    if skippingNumber>0
        rawMovie=rawMovie(:,:,1:skippingNumber:end);
    end

    template=mean(rawMovie,3);
    maxtemplate = double(max(rawMovie,[],3));
    dftemplate=maxtemplate-template;
    if gaussianBlur
        dftemplate = conv2(dftemplate,fspecial('gaussian',[3 3], 2),'same');    
    end

        
end