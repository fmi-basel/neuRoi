%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021
%TODO exchange 513 with height or width +1

function [xcorr, ycorr, height, width]= fcn_LoadRawTransformation(transformationPath)
    %read file 
    tempcell = readcell(transformationPath);
    
    %set height and width
    firstrow = split(tempcell(1), "=");
    width=str2num(['uint16(',cell2mat(firstrow(2)),')']);
    
    secondrow = split(tempcell(2), "=");
    height=str2num(['uint16(',cell2mat(secondrow(2)),')']);
    
    %create xcorr
    xcorr=zeros(width,height);
    for i=1:height
        temprow= str2double(split(tempcell(i+3)));
        temprow= temprow(~isnan(temprow));
        xcorr(:,i)= temprow+1;    
    end
      
    %create ycorr
    ycorr=zeros(width,height);
    for i=1:height
        temprow= str2double(split(tempcell(i+3+height+1)));
        %cell2mat(§
        temprow= temprow(~isnan(temprow));
        ycorr(:,i)= temprow+1; 
    end
    
end