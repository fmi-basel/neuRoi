function optionStr = convertOptionToString(option)
    nameArray = fieldnames(option);
    stringArray = {};
    for i = 1:length(nameArray)
        name = nameArray{i};
        value = option.(name);
        stringArray{i} = sprintf('%s: %s',name,mat2str(value));
    end
    optionStr = [sprintf(['%s; '],stringArray{1:end-1}), ...
                 stringArray{end}];
    
end
