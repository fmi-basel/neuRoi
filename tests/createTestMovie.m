function movieStruct = createTestMovie(varargin)
pa = inputParser;
addParameter(pa, 'startList', [6, 4, 8], @ismatrix);
addParameter(pa, 'durList', [3, 4, 4], @ismatrix);
addParameter(pa, 'baseList', [1, 3, 4], @ismatrix);
addParameter(pa, 'ampList', [10, 9, 2], @ismatrix);
addParameter(pa, 'affineMat', [1, 0, 0; 0, 1, 0; 0, 0, 1], @ismatrix);
parse(pa,varargin{:})
pr = pa.Results;

movieSize = [12, 10, 20];
mockMovie.name = 'mock_movie';
mockMovie.meta = struct('width', movieSize(1),...
                        'height', movieSize(2),...
                        'totalNFrame', movieSize(3));
rawMovie = zeros(movieSize);
roiList = {[3,3;3,4;3,5;4,3;4,4;4,5;5,3;5,4;5,5]
           [5,8;5,9;6,8;6,9;7,8;7,9;6,7],
           [9,6;9,7;10,6;10,7;11,6]
          };

timeTraceMat = zeros(length(roiList), movieSize(3));
for k=1:length(roiList)
    roi=roiList{k};
    start = pr.startList(k);
    dur = pr.durList(k);
    base = pr.baseList(k);
    amp = pr.ampList(k);
    mask=zeros(movieSize(1:2));
    mask(sub2ind(movieSize(1:2),roi(:,1), roi(:,2))) = 1;
    dynamic = computeDynamic(mask, start, dur, base, amp, movieSize);
    rawMovie = rawMovie + dynamic;
    timeTrace = computeTimeTrace(start, dur, base, amp, movieSize(3));
    timeTraceMat(k, :) = timeTrace;
end
rawMovie = shiftMovieYx(rawMovie, offsetYx)
movieStruct.rawMovie = rawMovie;
movieStruct.anatomy = mean(rawMovie, 3);
movieStruct.timeTraceMat = timeTraceMat;
end


function warped = warpMovie(rawMovie, affineMat)
    tform = affinetform2d(affineMat)
    warped = imwarp(rawMovie,tform);
end



