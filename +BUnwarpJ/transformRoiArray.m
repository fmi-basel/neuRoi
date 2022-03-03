function roiArrayStack = transformRoiArray(templateRoiArray,mapSize,rawFileList,transformDir)
RoiMap = roiFunc.convertRoiArrayToMask(templateRoiArray.roiArray,mapSize);

    % Dilate the RoiMap for 1 pixel, so to prevent the resulted ROIs from being shrinked
    se = strel('diamond',1);
    RoiMap = imdilate(RoiMap,se);

    for i=1:length(rawFileList)
        [~,trialName,~] = fileparts(rawFileList{i});
        transformName = iopath.modifyFileName(rawFileList{i},'anatomy_','_Norm_transformationRaw','txt');
        OutputMask= BUnwarpJ.fcn_ApplyRawTransformation(RoiMap,fullfile(transformDir,'TransformationsRaw',transformName));
        
        %create FreehandRois from tranformed roi masks
        roiArray = RoiFreehand.empty();
        for j=1:max(max(OutputMask))
            [col,row]=find(OutputMask==j); %not needed anymore

            if ~isempty(row)
                %from TrialModel
                roiMask = OutputMask==j;
                 poly = roiFunc.mask2poly(roiMask);
                 if length(poly) > 1
                     % TODO If the mask corresponds multiple polygon,
                     % for simplicity,
                     % take the largest polygon
                     warning(sprintf('ROI %d has multiple components, only taking the largest one.',j))
                     pidx = find([poly.Length] == max([poly.Length]));
                     poly = poly(pidx);
                 end
                 position = [poly.X',poly.Y'];
                 newroi = RoiFreehand(position);

                 newroi.tag = j;
                 roiArray(end+1) = newroi;
            else
                 tempString=strcat("lost roi detected: roi number: " ,int2str(j)," in trial: ", int2str(i));
                 disp(tempString);
            end
        end
        roiArrayStack(i).roi=roiArray;
        roiArrayStack(i).trial=trialName;
        tempString= strcat(int2str(i), " of ",int2str(length(rawFileList)), " transformation done at ",datestr(now,'HH:MM:SS.FFF'));
        disp(tempString);
    end

