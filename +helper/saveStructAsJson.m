function saveStructAsJson(myStruct,outFilePath)
jsonStr = jsonencode(myStruct);
fid = fopen(outFilePath, 'w');
if fid == -1, error('Cannot create JSON file'); end
fwrite(fid, jsonStr, 'char');
fclose(fid);
