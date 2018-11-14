function tag = generateRandomTag(tagLen)
symbols = ['a':'z' 'A':'Z' '0':'9'];
idx = randsample(1:length(symbols),tagLen);
tag = symbols(idx);
