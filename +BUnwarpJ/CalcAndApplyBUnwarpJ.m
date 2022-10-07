%%%%% Jan Eckhardt/FMI/AG Friedrich/Basel/Switzerland 08.2021

function [varargout]= CalcAndApplyBUnwarpJ(referenceImage, trialImages, ReferenceMask,...
                                           PathInput, ROIType, OutputFreehandROI,...
                                           useSift,SIFTParameters, SaveFolder,...
                                           BUnwarpJParameters, mapSize)

%Path are supposed to be tiff for images
%PathInput optional: Default is true
%ROIType: 0=Matrix, 1=ImagejMask(stardist), 2=FreehandRois
%OutputFreehandROI optional: Default is false
%trialImages is supposed to be a Array of strings
%Transformations are saved in the folder of the first trialPath- if not
%path->folder dialog
%PathInput: array order=[referenceImage, trialImages, ReferenceMask];
%true=Path, false=data input
%useSift: false=non; true=SIFT;;

%TODO: Console progress!! almost done

width = mapSize(2);
height =  mapSize(1);

SaveMatricesAsTifs = false;
ApplyTransformWithBUnwaprJ = false;
SkipTransformationCalc =false;
AlternativeSaveFolder = false;
LandmarksWeigth= 0;
ImageWeights= 0;



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

if ~exist('useSift','var')
        useSift= false;        
end

if ~exist('SIFTParameters','var')
    SIFTParameters=struct( 'Initial_Gaussion_Blur',1.6,...
                           'steps_per_scale_octave',3,...
                           'minimum_image_size',32,...
                           'maximum_image_size',512,...
                           'feature_descriptor_size',4,...
                           'feature_descriptor_orientation_bins',8,...
                           'closest_next_closest_ratio',0.8,...
                           'maximal_alignment_error',50,...
                           'minimal_inlier_ratio',0.05,...
                           'expected_transformation',1); %https://imagej.net/plugins/feature-extraction;
end

if ~exist('SaveFolder','var')
        SaveFolder= string([]);
else
    AlternativeSaveFolder=true;
end

if ~exist('BUnwarpJParameters','var')
    transformationGridStart =0;
    transformationGridEnd =2;
else
    transformationGridStart = BUnwarpJParameters.transformationGridStart;
    transformationGridEnd = BUnwarpJParameters.transformationGridEnd;
end

%%Change this according to your imagej
if strcmp(getenv('COMPUTERNAME'),'F462L-3B17DA')
    javaaddpath('C:\Users\eckhjan\fiji-win64\Fiji.app\plugins\bUnwarpJ_-2.6.13.jar');
    javaaddpath('C:\Users\eckhjan\fiji-win64\Fiji.app\jars\ij-1.53f.jar');
    javaaddpath('C:\Users\eckhjan\fiji-win64\Fiji.app\plugins\mpicbg_-1.4.1.jar');%for SIFT
    javaaddpath('C:\Users\eckhjan\fiji-win64\Fiji.app\jars\mpicbg-1.4.1.jar');%for SIFT
elseif strcmp(getenv('COMPUTERNAME'),'VCW1050')
    javaaddpath('C:\fiji-win64\Fiji.app\plugins\bUnwarpJ_-2.6.13.jar');
    javaaddpath('C:\fiji-win64\Fiji.app\jars\ij-1.53q.jar');
    javaaddpath('C:\fiji-win64\Fiji.app\plugins\mpicbg_-1.4.1.jar');%for SIFT
    javaaddpath('C:\fiji-win64\Fiji.app\jars\mpicbg-1.4.1.jar');%for SIFT
else
    imagejPaths = BUnwarpJ.getImagejPaths();
    for k=1:length(imagejPaths)
        javaaddpath(imagejPaths{k})
    end
end



%ImageJ Loader
ImageJ_LoaderEngine=ij.io.Opener();

if PathInput(1)
    %%TODO calculate all transformations-Bunwarp- load images in loop and
    %%call plugin
    
    
    %Reference = read(referenceImage);
    Reference=ImageJ_LoaderEngine.openImage(referenceImage);
 
    %[Referencefilepath,Referencename,Referenceext] = fileparts(referenceImage);
else

    if AlternativeSaveFolder
        TempSavePath = fullfile(SaveFolder,"Reference");
    else
        %%Let the user select a Path to save the
        %%transformations/trialimages
        TempSavePath = uigetdir('C:\',"Choose a folder to store temp data and transformations");
          
    end
    imwrite(uint8(referenceImage), fillfile(TempSavePath,"referenceImage")); 
    referenceImage=fillfile(TempSavePath,"referenceImage");
    Reference=ImageJ_LoaderEngine.openImage(referenceImage);
end

if PathInput(2)
    
    %%create Transformationfolders
    if AlternativeSaveFolder
        TempSavePath = SaveFolder;
    else
        [TempSavePath,name,ext] = fileparts(trialImages(1));
    end
else
    
    if AlternativeSaveFolder
        TempSavePath = fullfile(SaveFolder,"Reference");
    else
        %%Let the user select a Path to save the
        %%transformations/trialimages
        TempSavePath = uigetdir('C:\',"Choose a folder to store temp data and transformations");  
    end
   
    
    
    %%create trial tiffs so they can be loaded as imagej image
    TrialFolder=fullfile(TempSavePath,"/trialImages"); 
    mkdir(TrialFolder);
    for i=1:length(trialImages)
       TempPath =fullfile(TrialFolder,strcat("/Trial",int2str(i),".tiff"));
       imwrite(trialImages(i),TempPath);
       trialImages2(i)=TempPath;
    end
    trialImages=trialImages2;
    
end


    

if PathInput(3)
    
    if ~PathInput(1) & ~PathInput(2)
    if AlternativeSaveFolder
         TempSavePath = SaveFolder;
    else
        %%Let the user select a Path to save the
        %%transformations/trialimages
        TempSavePath = uigetdir('C:\',"Choose a folder to store temp data and transformations");  
    end
    end
    
    %%Load reference mask 
    tempString= strcat("Load Referencemask at ",datestr(now,'HH:MM:SS.FFF'));
    disp(tempString);
     
     
     
  
    %%Load refernce mask depending on the type
    switch ROIType
        case 2 %FreehandRoi masks
            
            %%need to be done-load mat files etc-should be done-need to be
            %%tested
            FreehandroiArray = load(ReferenceMask);
            RoiMap = createROIMaskFromFreehandROI(FreehandroiArray.roiArray,width, height);
            RoiNumber =length(FreehandroiArray.roiArray);
            
        
        case 1 %ImageJ masks/from Stardist
            
            RoiFiles=dir(fullfile(ReferenceMask,'/*.roi'));
            RoiFiles=struct2cell(RoiFiles);

            fileName =RoiFiles(1,:);
            fileDir  = RoiFiles(2,:);
            filePath = fullfile(fileDir,fileName);
    
            
            [jroiArray] = ReadImageJROI(filePath);
            RoiMap=createROIMaskFromImageJRoi(jroiArray,width, height);
            RoiNumber =length(jroiArray);
          


        case 0 %matrix masks

            RoiMap=uint16(imread(ReferenceMask));
            %%roiNumber has to be done
    end

else
    
    switch ROIType
         case 2 %FreehandRoi masks
             RoiMap = createROIMaskFromFreehandROI(ReferenceMask,width, height);
             RoiNumber =length(ReferenceMask);
         case 1 %ImageJ masks/from Stardist
              RoiMap=createROIMaskFromImageJRoi(ReferenceMask,width, height);
              RoiNumber =length(ReferenceMask);
         case 0 %matrix masks
             RoiMap = ReferenceMask;
              %%roiNumber has to be done
    end
    
    
    
end

rawTransformationFolder = fullfile(TempSavePath, "/TransformationsRaw");
transformationFolder = fullfile(TempSavePath, "/Transformations");
mkdir(transformationFolder);
mkdir(rawTransformationFolder);
if SaveMatricesAsTifs

    TiffFolder = fullfile(TempSavePath, "/MasksAsTiff");
    mkdir(TiffFolder);

end
    
        

if ~SkipTransformationCalc
    BUnwarpJ.computeTransformation(trialImages, referenceImage,...
                                   transformationFolder, rawTransformationFolder,...
                                   useSift, transformationGridStart,...
                                   transformationGridEnd)
end


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
trialNameList = cellfun(@(x) helper.getFileName(x), trialImages, 'UniformOutput', false);
rawTransformList = cellfun(@(x) fullfile(rawTransformationFolder, strcat(x, '_transformationRaw.txt')), trialNameList, 'UniformOutput', false);
transformedMasks = BUnwarpJ.transformMasks(RoiMap, rawTransformList);    

if SaveMatricesAsTifs
    for k=1:size(transformedMasks, 1)
        imwrite(uint16(transformedMasks(k, :, :)),...
                fullfile(TiffFolder,sprintf("mask.tif", k)));
    end
end

if OutputFreehandROI
    for k=1:size(transformedMasks, 1)
        [filepath,name,ext] = fileparts(trialImages(k));
        roiArray = convertMaskToRoiArray(mask)
        roiArrayList(k).roi=roiArray;
        roiArrayList(k).trial=name;
    end
    varargout{1} = roiArrayList;
else
    varargout{1} = transformedMasks;
end

%%use BunwarpJ to transform reference mask and save it as tiff
%%as comparison and debugging
if ApplyTransformWithBUnwaprJ
     for i=1:length(trialImages)
        TransfMask =MaskToTranf.duplicate();
        bunwarpj.bUnwarpJ_.applyTransformToSource( fullfile(transformationFolder,strcat(name,"_transformation.txt")),MaskToTranf,TransfMask);
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
        bunwarpj.bUnwarpJ_.applyRawTransformToSource( fullfile(rawTransformationFolder,strcat(name,"_transformationRaw.txt")),MaskToTranf,TransfMask);
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

    RoiMap = zeros( width,heigth, 'uint16');

    for i=1:nRoi
        newroi=FreehandroiArray(i);
        binaryImage =double(newroi.tag)* newroi.createMask([ width,heigth]);
        RoiMap= min(RoiMap+ uint16(binaryImage),double(newroi.tag));
    end

end

function RoiMap=createROIMaskFromImageJRoi(jroiArray,heigth, width)
     RoiMap = zeros(heigth, width, 'uint16');
     for k=1:length(jroiArray)
        jroi = jroiArray{k};
        RoiMap=min( RoiMap +uint16(k* poly2mask(jroi.mnCoordinates(:,1),jroi.mnCoordinates(:,2),heigth, width)),k);
        
     end   
end
