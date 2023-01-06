function stack = createStack()
    nTrial = 3;
    affineMats = {};
    affineMats{1} = [1.1 0 0; 0 0.9 0; -5 8 1];
    affineMats{2} = [0.8 0 0; 0 1 0; 10 -20 1];
    movieStructList = createTestMovies(affineMats{1}, affineMats{2});
    anatomyStack = cellfun(@(x) x.anatomy, movieStructList, 'UniformOutput', false);
    anatomyStack = cat(3, anatomyStack{:});
    responseStack = anatomyStack;
    
    roiArrStack = cellfun(@(x) roiFunc.RoiArray('maskImg', x.mask),...
                          movieStructList, 'UniformOutput', false);
    
    roiArrStack = splitRoiArrStack(roiArrStack);

    trialNameList = arrayfun(@(x) sprintf('trial%02d', x), 1:nTrial,...
                             'UniformOutput', false);

    imageSize = size(movieStructList{1}.anatomy);
    offsetYxList = {};
    transformStack = Bunwarpj.Transformation.empty();
    transfomrInvStack = Bunwarpj.Transformation.empty();
    offsetYxList{1} = [0, 0];
    transformStack(1) = Bunwarpj.Transformation('type', 'identity');
    transformInvStack(1) = Bunwarpj.Transformation('type', 'identity');

    for k=2:3
        offsetYxList{k} = affineMats{k-1}(3, 1:2);
        afmat = affineMats{k-1}(1:2, 1:2);
        transformStack(k) = createTransform(imageSize, afmat);
        transformInvStack(k) = createTransform(imageSize, inv(afmat));
    end

    stack.trialNameList = trialNameList;
    stack.anatomyStack = anatomyStack;
    stack.responseStack = responseStack;
    stack.roiArrStack = roiArrStack;
    stack.offsetYxList = offsetYxList;
    stack.transformStack = transformStack;
    stack.transformInvStack = transformInvStack;
    stack.movieStructList = movieStructList;
end

function troiArrStack = splitRoiArrStack(roiArrStack)
    troiArrStack = roiFunc.RoiArray.empty();
    for k=1:length(roiArrStack)
        troiArrStack(k) = splitRoiArr(roiArrStack{k});
    end
end

function roiArr = splitRoiArr(roiArr)
    tags1 = [1, 2];
    tags2 = [3, 4];
    roiArr.renameGroup(roiArr.DEFAULT_GROUP, 'region1');
    roiArr.addGroup('region2');
    roiArr.putRoisIntoGroup(tags1, 'region1');
    roiArr.putRoisIntoGroup(tags2, 'region2');
end

function movieStructList = createTestMovies(affineMat2, affineMat3)
    movieStructList = {};
    movieStructList{1} = testUtils.createMovie();
    movieStructList{2}= testUtils.createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    movieStructList{3}= testUtils.createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end

function transf = createTransform(imageSize, afmat)
    xcorr = repmat((1:imageSize(2)), [imageSize(1), 1]);
    ycorr = repmat((1:imageSize(1)), [imageSize(2), 1])';
    xycorr = cat(3, xcorr, ycorr);
    
    txycorr = pagemtimes(permute(xycorr, [2, 3, 1]), afmat);
    txycorr = permute(txycorr, [3, 1, 2]);
    transf = Bunwarpj.Transformation('type', 'bunwarpj',...
                                     'xcorr', txycorr(:, :, 1),...
                                     'ycorr', txycorr(:, :, 2),...
                                     'imageSize', imageSize);
end
