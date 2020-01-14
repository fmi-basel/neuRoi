function odor = getOdorFromFileName(fileName)
odor = regexp(fileName,'_o\d+([a-zA-Z]*)_','tokens');
odor = odor{1}{1};
