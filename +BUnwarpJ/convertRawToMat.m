function convertRawToMat(rawTransFile, matFile)
    [transform.xcorr, transform.ycorr, transform.height, transform.width] = BUnwarpJ.fcn_LoadRawTransformation(rawTransFile);
    save(matFile, '-struct', 'transform')
end

