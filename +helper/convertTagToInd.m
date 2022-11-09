function ind = convertTagToInd(tag,prefix)
indStr = regexp(tag,[prefix '_(\d+)'],'tokens');
ind = str2num(indStr{1}{1});
