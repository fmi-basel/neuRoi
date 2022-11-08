function stack = createStack()
    nTrial = 3;
    affineMats = {};
    affineMats{1} = [1 0 0; 0 1 0; -5 8 1];
    affineMats{2} = [1 0 0; 0 1 0; 10 -20 1];
    movieStructList = createTestMovies(affineMats{1}, affineMats{2});
    anatomyStack = cellfun(@(x) x.anatomy, movieStructList, 'UniformOutput', false);
    responseStack = anatomyStack;
    
    roiArrStack = cellfun(@(x) roiFunc.RoiArray('maskImg', x.mask),...
                          movieStructList, 'UniformOutput', false);
    
    roiArrStack = splitRoiArrStack(roiArrStack);

    trialNameList = arrayfun(@(x) sprintf('trial%02d', x), 1:nTrial,...
                             'UniformOutput', false);

    imageSize = size(movieStructList{1}.anatomy);
    transformStack = {};
    transformStack{1} = BUnwarpJ.Transformation('identity');
    for k=2:3
        transformStack{k} = createTransform(imageSize, affineMats{k-1}(3, 1:2));
    end

    transfomrInvStack = {};
    transformInvStack{1} = BUnwarpJ.Transformation('identity');
    for k=2:3
        transformInvStack{k} = createTransform(imageSize, -affineMats{k-1}(3, 1:2));
    end

    stack.trialNameList = trialNameList;
    stack.anatomyStack = anatomyStack;
    stack.responseStack = responseStack;
    stack.roiArrStack = roiArrStack;
    stack.transformStack = transformStack;
    stack.transformInvStack = transformInvStack;
end

function troiArrStack = splitRoiArrStack(roiArrStack)
    troiArrStack = {};
    for k=1:length(roiArrStack)
        troiArrStack{k} = splitRoiArr(roiArrStack{k});
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
    movieStructList{1} = createMovie();
    movieStructList{2}= createMovie('ampList', [45, 60, 100, 40], 'affineMat', affineMat2);
    movieStructList{3}= createMovie('ampList', [60, 50, 80, 50], 'affineMat', affineMat3);
end

function transf = createTransform(imageSize, offsetYx)
    xcorr = repmat((1:imageSize(2)) + offsetYx(1), [imageSize(1), 1]);
    ycorr = repmat((1:imageSize(1)) + offsetYx(2), [imageSize(2), 1]);
    transf = BUnwarpJ.Transformation('bunwarpj', xcorr, ycorr', imageSize);
end
