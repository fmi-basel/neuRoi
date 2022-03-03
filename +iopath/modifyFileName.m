function mName = modifyFileName(fileName,prefix,appendix,extension)
[directory, baseName, oriExt] = fileparts(fileName);
mName = strcat(prefix,baseName,appendix,'.',extension);
