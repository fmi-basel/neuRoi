function binned = binMovie(rawMovie,shrinkFactors,binMethod)
% BINMOVIE bin the movie at x, y and z axis
%     Args:
%         rawMovie (NxMxL matrix): matrix containing raw movie
%         data with each axis representing x, y, and z (time).
%         shrinkFactors (1x3 array): shrink factor on x, y and z axis.
%         binMethod (char): method for binning the data, can be
%         'mean', 'max' or 'min'.
%     Returns:
%         binned (PxQxW matrix): matrix contaning binned movie.
    
    switch binMethod
      case 'max'
        binfun=@max;
      case 'min'
        binfun=@min;
      case 'mean'
        binfun=@mean;
      otherwise
        error('Unrecognized bin method')
    end
    % blockfun = @ (blockStruct) fun(blockStruct.data);

    if any(shrinkFactors < 1)
        error('shrink factors must be integers >= 1!')
    end
    
    if any(mod(size(rawMovie),shrinkFactors))
        warning(['Shrink factors not divide the dimensions of movie ' ...
               'matrix. Residues after last block truncated.'])
        oldMovieSize = size(rawMovie);
        mvsz = oldMovieSize-mod(oldMovieSize,shrinkFactors);
        rawMovie = rawMovie(1:mvsz(1),1:mvsz(2),1:mvsz(3));
    end

    movieSize = size(rawMovie);
    binnedSize = movieSize./shrinkFactors;
    doBinningXy = any(shrinkFactors(1:2) > 1);
    doBinningZ = shrinkFactors(3) > 1;
    
    if doBinningXy
        % shrink in X and Y
        binnedXy = zeros(binnedSize(1),binnedSize(2),movieSize(3));
        for k = 1:movieSize(3)
            binnedXy(:,:,k) = bin2D(rawMovie(:,:,k),shrinkFactors(1:2));
        end
        if ~doBinningZ
            binned = binnedXy;
        end
    end
    
    if doBinningZ
        % shrink in Z
        if doBinningXy
            movieToBin = binnedXy;
        else
            movieToBin = rawMovie;
        end
        binned = binZ(movieToBin,shrinkFactors(3));
    end
    
function binnedVec = bin1D(vec,shrinkFactor,binMethod)
    if mod(length(vec),shrinkFactor)
        error('Shrink factor must divide the length of the vector!')
    end
    bsize = [length(vec)/shrinkFactor, shrinkFactor];
    binnedVec = reshape(vec,bsize);
    switch binMethod
      case 'max'
        binnedVec = max(binnedVec,[],2);
      case 'min'
        binnedVec = min(binnedVec,[],2);
      case 'mean'
        binnedVec = mean(binnedVec,2);
      otherwise
        error('Unrecognized bin method')
    end

function binnedMat = bin2D(mat,shrinkFactors,binMethod)
% TODO max and mean
    if any(mod(size(mat),shrinkFactors))
        error('Shrink factors must divide the sizes of the vector!')
    end
    matSize = size(mat);
    shp = [shrinkFactors(1),matSize(1)/shrinkFactors(1),...
          shrinkFactors(2),matSize(2)/shrinkFactors(2)];
    binnedMat = permute(reshape(mat,shp),[1 3 2 4]);
    binnedMat = squeeze(mean(mean(binnedMat,1),2));

    
function binnedMat = binZ(mat,shrinkFactor,binMethod)
    if mod(size(mat,3),shrinkFactor)
        error('Shrink factor must divide the length in Z!')
    end
    
    matSize = size(mat);
    shp = [matSize(1),matSize(2),shrinkFactor,matSize(3)/ ...
           shrinkFactor];
    binnedMat = reshape(mat,shp);
    binnedMat = squeeze(mean(binnedMat,3));
