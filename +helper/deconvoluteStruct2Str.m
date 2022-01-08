function output = deconvoluteStruct2Str(input,parentStruct,parentName)
    %JE: deconvolute nested struct to string array
    %recursivly call if nested structure with parentStruct to append
    %only for 1xn struct
    UseParentStruct= false;
    if exist('parentStruct','var') && isstruct(parentStruct) &&exist('parentName','var') && ischar(parentName)
        UseParentStruct=true;
        output=parentStruct;
    else
        output = string;
    end
    nameArray = fieldnames(input);
    
    for i = 1:length(nameArray)
        name = nameArray{i};
        if isstruct(input.(name))
            output =helper.deconvoluteStruct2Str(input.(name),output,name);
        else
            value = string(input.(name));
           if length(value)>1
                outputString= string();
                for j=1:length(value)
                    if j==1
                        outputString=strcat("[",string(value(j)));
                    elseif j==length(value)
                        outputString=strcat(outputString," ",string(value(j)),"]");
                    else
                        outputString=strcat(outputString," ",string(value(j)));
                    end
                end
                value=outputString;
            end
            if UseParentStruct
                output(i)=sprintf('%s_%s:%s',parentName,name,value);
            else
                output(i)=sprintf('%s:%s',name,value)
            end
        end
    end
   
end
