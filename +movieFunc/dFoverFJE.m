function responseMap = dFoverFJE(rawMovie,offset,lowerPercentile,higherPercentile, skippingNumber, substractMinimum )
   
    if skippingNumber>0
        subRawMovie=rawMovie(:,:,1:skippingNumber:end);
    else
        subRawMovie=rawMovie;
    end

    fZeroRawPercentile=prctile(subRawMovie,lowerPercentile,3);
    fZeroRaw=double(subRawMovie);
    fZeroRaw(fZeroRaw> fZeroRawPercentile)=NaN;
    fZeroRaw =mean(fZeroRaw,3,"omitnan");

    dfRawPercentile=prctile(subRawMovie,higherPercentile,3);
    dfRaw=double(subRawMovie);
    dfRaw(dfRaw< dfRawPercentile)=NaN;
    dfRaw =mean(dfRaw,3,"omitnan");
    
     if substractMinimum
        stackMin=min(rawMovie,[],3);
        stackMin=double(stackMin);
        fZeroRaw=fZeroRaw-stackMin;
        dfRaw=dfRaw-stackMin;
    end

    fZero = conv2(fZeroRaw,fspecial('gaussian',[3 3], 1),'same');
    df = (dfRaw - fZero)./(fZero-offset);
    responseMap = conv2(df,fspecial('gaussian',[3 3], 2),'same');
end