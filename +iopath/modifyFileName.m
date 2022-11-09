function mName = modifyFileName(fileName,prefix,appendix,extension)
baseName = regexprep(fileName,'\.[a-zA-Z0-9]*$','');
mName = strcat(prefix,baseName,appendix,'.',extension);
