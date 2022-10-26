function movieStruct = createMovie(varargin)
pa = inputParser;
addParameter(pa, 'startList', [6, 4, 8, 5], @ismatrix);
addParameter(pa, 'durList', [3, 4, 4, 3], @ismatrix);
addParameter(pa, 'baseList', [20, 30, 40, 20], @ismatrix);
addParameter(pa, 'ampList', [50, 100, 90, 60], @ismatrix);
addParameter(pa, 'affineMat', [1, 0, 0; 0, 1, 0; 0, 0, 1], @ismatrix);
parse(pa,varargin{:})
pr = pa.Results;

movieSize = [128, 144, 22];
mockMovie.name = 'mock_movie';
mockMovie.meta = struct('width', movieSize(1),...
                        'height', movieSize(2),...
                        'totalNFrame', movieSize(3));
rawMovie = zeros(movieSize);
roiList = {[30, 39; 30, 39],
           [70, 79; 50, 59],
           [40, 49; 90, 99],
           [100, 109; 30, 39]
          };

templateMask = zeros(movieSize(1:2));
timeTraceMat = zeros(length(roiList), movieSize(3));
for k=1:length(roiList)
    roi=roiList{k};
    start = pr.startList(k);
    dur = pr.durList(k);
    base = pr.baseList(k);
    amp = pr.ampList(k);
    mask=zeros(movieSize(1:2));
    mask(roi(1,1):roi(1,2), roi(2,1):roi(2,2)) = k;
    
    dynamic = computeDynamic(mask, start, dur, base, amp, movieSize);
    rawMovie = rawMovie + dynamic;
    
    templateMask = templateMask + k * mask;
    timeTrace = computeTimeTrace(start, dur, base, amp, movieSize(3));
    timeTraceMat(k, :) = timeTrace;
end
rawMovie = warpMovie(rawMovie, pr.affineMat);
movieStruct.rawMovie = rawMovie;
movieStruct.anatomy = mean(rawMovie, 3);
movieStruct.timeTraceMat = timeTraceMat;
movieStruct.templateMask = templateMask;
movieStruct.mask = warpMovie(templateMask, pr.affineMat);
end


function timeTrace = computeTimeTrace(start, dur, base, amp, totalT)
    timeTrace =  base * ones(1, totalT);
    timeTrace(start:start+dur-1) = amp;
end

function dynamic = computeDynamic(mask, start, dur, base, amp, movieSize)
    dynamic = zeros(movieSize);
    dynamic = base * repmat(mask, 1, 1, movieSize(3));
    dynamic(:, :, start:start+dur-1) = amp * repmat(mask, 1, 1, dur);
end

function warped = warpMovie(rawMovie, affineMat)
    tform = affine2d(affineMat);
    warped = movieFunc.imwarpSame(rawMovie,tform);
end



