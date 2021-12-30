function optionStr = convertOptionToString(option,prefix)
    %JE modified for nested struct
    %recursivly call if nested structure with prefix=struct name
    %prefix only usefull in recursion!
    UsePrefix= false;
    if exist('prefix','var') && ischar(prefix)
        UsePrefix=true;  
    end
    nameArray = fieldnames(option);
    stringArray = {};
    nestedStringsCount= 0 ;
    for i = 1:length(nameArray)
        name = nameArray{i};
        if isstruct(option.(name))
            nestedOptions =helper.convertOptionToString(option.(name),name);
            nestedStringsCount=nestedStringsCount+length(nestedOptions);
            stringArray=[stringArray,nestedOptions];
        else
            value = option.(name);
            if UsePrefix
                stringArray{i+nestedStringsCount} = sprintf('%s: %s',strcat(prefix,".",name),mat2str(value));
            else
                stringArray{i+nestedStringsCount} = sprintf('%s: %s',name,mat2str(value));
            end
        end
    end
    if UsePrefix
           optionStr= stringArray;
    else
        optionStr = [sprintf(['%s; '],stringArray{1:end-1}), ...
                 stringArray{end}];
    end
end
