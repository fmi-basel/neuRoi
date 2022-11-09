function output = deconvoluteStruct(input,parentStruct,parentName)
    %JE: deconvolute nested struct
    %recursivly call if nested structure with parentStruct to append
    %only for 1xn struct
    UseParentStruct= false;
    if exist('parentStruct','var') && isstruct(parentStruct) &&exist('parentName','var') && ischar(parentName)
        UseParentStruct=true;
        output=parentStruct;
    else
        output = struct;
    end
    nameArray = fieldnames(input);
    
    for i = 1:length(nameArray)
        name = nameArray{i};
        if isstruct(input.(name))
            output =helper.deconvoluteStruct(input.(name),output,name);
        else
            value = input.(name);
            if UseParentStruct
                output.(strcat(parentName,'_',name))=value;
            else
                output.(name)=value;
            end
        end
    end
   
end