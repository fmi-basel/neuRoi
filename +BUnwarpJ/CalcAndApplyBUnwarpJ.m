%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021

function [TransformedMasks]= CalcAndApplyBUnwarpJ(ReferenceImage, TrialImages, ReferenceMask, PathInput,ROIType,OutputFreehandROI )

%Path are supposed to be tiff for images
%PathInput optional: Default is true
%ROIType: 0=Matrix, 1=ImagejMask(stardist), 2=FreehandRois
%OutputFreehandROI optional: Default is false
%TrialImages is supposed to be a Array of strings
%Transformations are saved in the folder of the first trialPath- if not
%path->folder dialog
%PathInput: array order=[ReferenceImage, TrialImages, ReferenceMask];
%true=Path, false=data input

%TODO: Console progress!!


SaveMatricesAsTifs = false;
ApplyTransformWithBUnwaprJ = false;
SkipTransformationCalc =false;
TransformationGridStart =0;
TransformationGridEnd =2;


if ~exist('PathInput','var')
     PathInput = [1,1,1];   
    %PathInput= true;
end

if ~exist('ROIType','var')
        ROIType= 0;
end

if ~exist('OutputFreehandROI','var')
        OutputFreehandROI= false;
end


%%Change this according to your imagej
javaaddpath('C:\Users\eckhjan\fiji-win64\Fiji.app\plugins\bUnwarpJ_-2.6.13.jar');
javaaddpath('C:\Users\eckhjan\fiji-win64\Fiji.app\jars\ij-1.53c.jar');



%ImageJ Loader
ImageJ_LoaderEngine=ij.io.Opener();

if PathInput(1)
    %%TODO calculate all transformations-Bunwarp- load images in loop and
    %%call plugin
    
    
    %Reference = read(ReferenceImage);
    Reference=ImageJ_LoaderEngine.openImage(ReferenceImage);
 
    %[Referencefilepath,Referencename,Referenceext] = fileparts(ReferenceImage);
else
    %%Let the user select a Path to save the
    %%transformations/trialimages
    TempSavePath = uigetdir('C:\',"Choose a folder to store temp data and transformations");
    imwrite(uint8(ReferenceImage), fillfile(TempSavePath,"ReferenceImage"));
    Reference=ImageJ_LoaderEngine.openImage(fillfile(TempSavePath,"ReferenceImage"));
    
end

if PathInput(2)
    
    %%create Transformationfolders
    [filepath,name,ext] = fileparts(TrialImages(1));
    
else
    
    if ~PathInput(1)
    %%Let the user select a Path to save the
    %%transformations/trialimages
    TempSavePath = uigetdir('C:\',"Choose a folder to store temp data and transformations"); 
    end
    filepath=TempSavePath;
    
    
    %%create trial tiffs so they can be loaded as imagej image
    TrialFolder=fullfile(TempSavePath,"/TrialImages"); 
    mkdir(TrialFolder);
    for i=1:length(TrialImages)
       TempPath =fullfile(TrialFolder,strcat("/Trial",int2str(i),".tiff"));
       imwrite(TrialImages(i),TempPath);
       TrialImages2(i)=TempPath;
    end
    TrialImages=TrialImages2;
    
end

    RawTransformationFolder = fullfile(filepath, "/TransformationsRaw");
    TransformationFolder = fullfile(filepath, "/Transformations");
    mkdir(TransformationFolder);
    mkdir(RawTransformationFolder);
    if SaveMatricesAsTifs
    
        TiffFolder = fullfile(filepath, "/MasksAsTiff");
        mkdir(TiffFolder);
    
    end
    

if PathInput(3)
    
    if ~PathInput(1) & ~PathInput(2)
    %%Let the user select a Path to save the
    %%transformations/trialimages
    TempSavePath = uigetdir('C:\',"Choose a folder to store temp data and transformations"); 
    end
    
    %%Load reference mask 
    tempString= strcat("Load Referencemask at ",datestr(now,'HH:MM:SS.FFF'));
    disp(tempString);
     
     
     
  
    %%Load refernce mask depending on the type
    switch ROIType
        case 2 %FreehandRoi masks
            
            %%need to be done-load mat files etc
            
            RoiMap = createROIMaskFromFreehandROI(FreehandroiArray,512, 512);
            
            
        
        case 1 %ImageJ masks/from Stardist
            
            RoiFiles=dir(fullfile(ReferenceMask,'/*.roi'));
            RoiFiles=struct2cell(RoiFiles);

            fileName =RoiFiles(1,:);
            fileDir  = RoiFiles(2,:);
            filePath = fullfile(fileDir,fileName);
    
            
            [jroiArray] = ReadImageJROI(filePath);
            RoiMap=createROIMaskFromImageJRoi(jroiArray,512, 512);
            RoiNumber =length(jroiArray);
          


        case 0 %matrix masks

            RoiMap=uint16(imread(ReferenceMask));
            %%roiNumber has to be done
    end

else
    
    switch ROIType
         case 2 %FreehandRoi masks
             RoiMap = createROIMaskFromFreehandROI(ReferenceMask,512, 512);
             RoiNumber =length(ReferenceMask);
         case 1 %ImageJ masks/from Stardist
              RoiMap=createROIMaskFromImageJRoi(ReferenceMask,512, 512);
              RoiNumber =length(ReferenceMask);
         case 0 %matrix masks
             RoiMap = ReferenceMask;
              %%roiNumber has to be done
    end
    
    
    
end
    
    
        

if ~SkipTransformationCalc

    for i=1:length(TrialImages)
        %TempTrial= read(TrialImages(i));
        TempTrial=ImageJ_LoaderEngine.openImage(TrialImages(i));

        [filepath,name,ext] = fileparts(TrialImages(i));

        tempString= strcat("Start calculating transformation at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
        %calculate Transformation
        transf=bunwarpj.bUnwarpJ_.computeTransformationBatch(...
        TempTrial,... %reference target image
        Reference,... %warped source image
        TempTrial.getMask,...
        Reference.getMask,...
        1,... %accuracy mode (0 - Fast, 1 - Accurate, 2 - Mono)
        0,... %image subsampling factor (from 0 to 7, representing 2^0=1 to 2^7 = 128)
        TransformationGridStart,... %(0 - Very Coarse, 1 - Coarse, 2 - Fine, 3 - Very Fine)
        TransformationGridEnd,... %(0 - Very Coarse, 1 - Coarse, 2 - Fine, 3 - Very Fine, 4 - Super Fine)
        0,... %divergence weight
        0,... %curl weight
        0,... %landmark weight
        1,... %image similarity weight
        10,... %consistency weight
        0.01); %stopping threshold

        %Save Transformation
        transf.saveDirectTransformation(fullfile(TransformationFolder,strcat(name,"_transformation.txt")));
        transf.saveInverseTransformation(fullfile(TransformationFolder,strcat(name,"_transformationInverse.txt")));

        %Transform to raw transformation
        TempTrial.show();
        bunwarpj.bUnwarpJ_.convertToRaw(fullfile(TransformationFolder,strcat(name,"_transformation.txt")),fullfile(RawTransformationFolder,strcat(name,"_transformationRaw.txt")),strcat(name,ext));
        bunwarpj.bUnwarpJ_.convertToRaw(fullfile(TransformationFolder,strcat(name,"_transformationInverse.txt")),fullfile(RawTransformationFolder,strcat(name,"_transformationInverseRaw.txt")),strcat(name,ext));
        TempTrial.close();


        tempString= strcat(int2str(i), " of ",int2str(length(TrialImages)), " transformation calculated at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);

    end

end

Reference.close();

%%Save reference Mask as tiff for debugging 
if SaveMatricesAsTifs
    imwrite(uint16(RoiMap),fullfile(TiffFolder,"mask0.tif"));
end

%%initiation to use BunwarpJ to transform reference mask and save it as tiff
if ApplyTransformWithBUnwaprJ
    if SaveMatricesAsTifs
        MaskToTranf=ImageJ_LoaderEngine.openImage(fullfile(TiffFolder,"mask0.tif"));
        TransfMask =MaskToTranf.duplicate(); 
    else
        imwrite(uint16(RoiMap),fullfile(TiffFolder,"mask0.tif"));
        MaskToTranf=ImageJ_LoaderEngine.openImage(fullfile(TiffFolder,"mask0.tif"));
        TransfMask =MaskToTranf.duplicate();
    end
end

tempString= strcat("Apply transformations to Referencemask at ",datestr(now,'HH:MM:SS.FFF'));
disp(tempString);
%%select output format (FreehandROI or Matrix) 
if OutputFreehandROI

    %nRoi = length(jroiArray);
    %tempMatrix= zeros(length(TrialImages),nRoi);
    %TransformedMasks=RoiFreehand.empty(length(TrialImages),nRoi,0);


%                 RoiMap=createROIMaskFromImageJRoi(jroiArray,512, 512);
%                 tempString= strcat("Apply transformations to Referencemask at ",datestr(now,'HH:MM:SS.FFF'));
%                 disp(tempString);
    for i=1:length(TrialImages) 

        [filepath,name,ext] = fileparts(TrialImages(i));
        OutputMask= fcn_ApplyRawTransformation(RoiMap , fullfile(RawTransformationFolder,strcat(name,"_transformationInverseRaw.txt")));

        %create FreehandRois from tranformed roi masks
        roiArray = RoiFreehand.empty();
        for j=1:RoiNumber
            %[col,row]=find(OutputMask==j); not needed anymore
            if ~isempty(row)
                %from TrialModel
                 poly = roiFunc.mask2poly(OutputMask==j);
                 if length(poly) > 1
                     % TODO If the mask corresponds multiple polygon,
                     % for simplicity,
                     % take the largest polygon
                     warning(sprintf('ROI %d has multiple components, only taking the largest one.',tag))
                     pidx = find([poly.Length] == max([poly.Length]));
                     poly = poly(pidx);
                 end
                 position = [poly.X',poly.Y'];
                 newroi = RoiFreehand(position);

                 %newroi = RoiFreehand([row,col]); old and wrong- need
                 %contour of roi, not all pixel values
                 newroi.tag = j;
                 roiArray(end+1) = newroi;
                 %TransformedMasks(i,j+1)=newroi;
            else
                 tempString=strcat("lost roi detected: roi number: " ,int2str(j)," in trial: ", int2str(i));
                 disp(tempString);
            end
        end
        TransformedMasks(i).roi=roiArray;
        TransformedMasks(i).trial=name;
        tempString= strcat(int2str(i), " of ",int2str(length(TrialImages)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
        if SaveMatricesAsTifs
            imwrite(uint16(OutputMask),fullfile(TiffFolder,strcat("mask",int2str(i),".tif")));
        end

    end



else

    TransformedMasks=zeros(length(TrialImages),512,512);
% 
%                 roiArray = convertFromImageJRoi(jroiArray);
% 
%                 nRoi = length(roiArray);
%                 RoiMap = zeros(512, 'uint16');
% 
%                 for i=1:nRoi
%                     newroi=roiArray(i);
%                     %newroi.imageSize=[512,512];
%                     nPositions=length(newroi.position);
%                     binaryImage =newroi.tag* newroi.createMask([512,512]);
%                     RoiMap= min(RoiMap+ uint16(binaryImage),newroi.tag);
%                 end

%                 if SaveMatricesAsTifs
%                     imwrite(uint16(RoiMap),strcat("C:\Data\eckhjan\Matlab_stuff\TestMatlab\anatomy\trials\mask0.tif"));
%                 end
%                 if ApplyTransformWithBUnwaprJ
%                     if SaveMatricesAsTifs
%                         MaskToTranf=ImageJ_LoaderEngine.openImage(strcat("C:\Data\eckhjan\Matlab_stuff\TestMatlab\anatomy\trials\mask0.tif"));
%                         TransfMask =MaskToTranf.duplicate(); 
%                     else
%                         imwrite(uint16(RoiMap),strcat("C:\Data\eckhjan\Matlab_stuff\TestMatlab\anatomy\trials\mask0.tif"));
%                         MaskToTranf=ImageJ_LoaderEngine.openImage(strcat("C:\Data\eckhjan\Matlab_stuff\TestMatlab\anatomy\trials\mask0.tif"));
%                         TransfMask =MaskToTranf.duplicate();
%                     end
%                 end

    for i=1:length(TrialImages)

        [filepath,name,ext] = fileparts(TrialImages(i));
        OutputMask= fcn_ApplyRawTransformation(RoiMap , fullfile(RawTransformationFolder,strcat(name,"_transformationRaw.txt")));
        TransformedMasks(i,:,:)=OutputMask;
        tempString= strcat(int2str(i), " of ",int2str(length(TrialImages)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString); 
        if SaveMatricesAsTifs
            imwrite(uint16(OutputMask),fullfile(TiffFolder,strcat("mask",int2str(i),".tif")));
        end

    end

end

%%use BunwarpJ to transform reference mask and save it as tiff
%%as comparison and debugging
if ApplyTransformWithBUnwaprJ
     for i=1:length(TrialImages)
        TransfMask =MaskToTranf.duplicate();
        bunwarpj.bUnwarpJ_.applyTransformToSource( fullfile(TransformationFolder,strcat(name,"_transformation.txt")),MaskToTranf,TransfMask);
        javaImage=TransfMask;
        % get image properties
        H=javaImage.getHeight;
        W=javaImage.getWidth;
        DataType=javaImage.getType;
        switch DataType
            case 0 
                wDataType='uint8';
            case 1
                wDataType='int16';
            case 2
                wDataType='single';
            case 6
                wDataType='uint16';
        end
        uwImage=typecast(javaImage.getBufferedImage.getData.getDataStorage,'uint8');
        uwImage = reshape(uwImage,W,H).';
        imwrite(uint16(uwImage),fullfile(TiffFolder,strcat("maskFromBUnwarpJ",int2str(i),".tif")));

        TransfMask =MaskToTranf.duplicate();
        bunwarpj.bUnwarpJ_.applyRawTransformToSource( fullfile(RawTransformationFolder,strcat(name,"_transformationInverseRaw.txt")),MaskToTranf,TransfMask);
        javaImage=TransfMask;
        % get image properties
        H=javaImage.getHeight;
        W=javaImage.getWidth;
        DataType=javaImage.getType;
        switch DataType
            case 0 
                wDataType='uint8';
            case 1
                wDataType='int16';
            case 2
                wDataType='single';
            case 6
                wDataType='uint16';
        end
        uwImage=typecast(javaImage.getBufferedImage.getData.getDataStorage,'uint8');
        uwImage = reshape(uwImage,W,H).';
        imwrite(uint16(uwImage),fullfile(TiffFolder,strcat("maskFromBUnwarpJRaw",int2str(i),".tif")));
     end
     MaskToTranf.close();
     TransfMask.close();
end


    

end


function RoiMap=createROIMaskFromFreehandROI(FreehandroiArray,heigth, width)
    nRoi= length(FreehandroiArray);

    RoiMap = zeros(heigth, width, 'uint16');

    for i=1:nRoi
        newroi=FreehandroiArray(i);
        binaryImage =newroi.tag* newroi.createMask([512,512]);
        RoiMap= min(RoiMap+ uint16(binaryImage),newroi.tag);
    end

end

function RoiMap=createROIMaskFromImageJRoi(jroiArray,heigth, width)
     RoiMap = zeros(heigth, width, 'uint16');
     for k=1:length(jroiArray)
        jroi = jroiArray{k};
        RoiMap=min( RoiMap +uint16(k* poly2mask(jroi.mnCoordinates(:,1),jroi.mnCoordinates(:,2),heigth, width)),k);
        
     end   
end
