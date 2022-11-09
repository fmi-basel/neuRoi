function rawFileName = getRawFileName(fileName,prefix,appendix,ext)
result = regexp(fileName,[prefix,'(.*)',appendix,'.',ext],'tokens');
if length(result)
    rawFileName = result{1}{1};
else
    rawFileName = [];
end

