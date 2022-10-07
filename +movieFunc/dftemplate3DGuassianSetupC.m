function dftemplate = dftemplate3DGuassianSetupC(rawMovie, skippingNumber,sigma)
    

   
    if skippingNumber>0
        Gauss3DStack=rawMovie(:,:,1:skippingNumber:end);
    else
        Gauss3DStack=rawMovie;
    end
    Gauss3DStack = imgaussfilt3(Gauss3DStack, sigma); 
    template=mean(Gauss3DStack,3);
    maxtemplate = double(max(Gauss3DStack,[],3));
    dftemplate=maxtemplate-template;
    

        
end