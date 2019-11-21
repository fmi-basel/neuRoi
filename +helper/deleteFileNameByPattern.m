function fileList = deleteFileNameByPattern(fileList, pattern)
matches = regexp(fileList,pattern);
keepIdx = cellfun('isempty',matches);
fileList = fileList(keepIdx);

