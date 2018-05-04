function resCorrMap = computeLocalCorrelation(rawMovie,tileSize)
% computeLocalCorrelation comupute local correlation for a movie
%            lcmap = computeLocalCorrelation(rawMovie,tileSize)
%            computes localcorrelation for rawMovie with the size
%            of movie defined by tileSize.

    mask=computeTileMask(tileSize);
    corrMap1 = tilingAndComputeCorrelation(rawMovie,tileSize,mask,0);
    corrMap2 = tilingAndComputeCorrelation(rawMovie,tileSize,mask,tileSize/2);
    resCorrMap = corrMap1 + corrMap2;
end


function mask = computeTileMask(tileSize)
    distMat = zeros(tileSize^2,tileSize^2);
    for i = 1:tileSize^2
        for j = 1:tileSize^2
            [x1, y1] = ind2sub(size(distMat),i);
            [x2, y2] = ind2sub(size(distMat),j);
            distMat(i,j) = norm([x1 y1]-[x2 y2]);
        end
    end

    mask = 1./(distMat+1);
    mask = mask - eye(size(mask)).*mask;
end


function corrMap = tilingAndComputeCorrelation(rawMovie,tileSize,mask,tileShift)
    corrMap = zeros(size(rawMovie(:,:,1)));
    nTile1 = floor((size(rawMovie,1)-tileShift)/tileSize);
    nTile2 = floor((size(rawMovie,2)-tileShift)/tileSize);
    for i = 1:nTile1
        disp([num2str(i),' strip out of ',num2str(nTile1)]);
        for j = 1:nTile2
            tind=getTileIndices(i,j,tileSize,tileShift);
            tileMovie = rawMovie(tind{1},tind{2},:);
            tileCorrMat = computeCorrelationSingleTile(tileMovie,mask);
            corrMap(tind{1},tind{2}) =  tileCorrMat;
        end
    end
end


function tileIndices = getTileIndices(i,j,tileSize,tileShift)
    tileIndices{1} = ((i-1)*tileSize:i*tileSize-1)+1+tileShift;
    tileIndices{2} = ((j-1)*tileSize:j*tileSize-1)+1+tileShift;
end


function tileCorrMat = computeCorrelationSingleTile(tileMovie,mask)
    tileSize = size(tileMovie,1);
    if size(tileMovie,2) ~= tileSize
        error('tile size for x and y are not equal')
    end
    tileMovie = reshape(tileMovie,[tileSize^2,size(tileMovie,3)]);
    tileMovie = im2double(tileMovie);
    tileCorr = corr(tileMovie');
    indizes = sum(tileCorr.*mask);
    tileCorrMat = reshape(indizes,[tileSize,tileSize]);
end
