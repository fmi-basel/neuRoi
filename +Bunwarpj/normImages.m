function normImages(imageList, normParam)
            
        function NewTrialPathArray=NormTrialsForBUnwarpJ(self,TrialPath, SavePath, ReferenceIndex,UseCLAHE, CLAHEParameters )
            if ~exist('ReferenceIndex','var')
                ReferenceIndex=1;
            end
            if ~exist('UseCLAHE','var')
                UseCLAHE=false;
            end
            if ~exist('CLAHEParameters','var')
                CLAHEParameters=struct("NumTiles",[8 8],'ClipLimit',0.02);
            end
            %Load trials
            for i = 1:length(TrialPath)
                tempImgArray(i,:,:)= imread(TrialPath(i)); 
                tempString= strcat("Loading trial ",int2str(i));
                disp(tempString);   
            end

            %match histo/calc CLAHE and save image
            NewTrialPathArray=strings(int8(length(TrialPath)),1);
            for i = 1:length(TrialPath)
                [filepath,name,ext] = fileparts(TrialPath(i));
                if i == ReferenceIndex
                    if ~UseCLAHE
                        NormImgArray(i,:,:)=tempImgArray(i,:,:);
                    else
                        NormImgArray(i,:,:)=adapthisteq(squeeze(tempImgArray(i,:,:)),"NumTiles",CLAHEParameters.NumTiles,'ClipLimit',CLAHEParameters.ClipLimit);
                    end
                else
                    if ~UseCLAHE
                        NormImgArray(i,:,:)=imhistmatch(tempImgArray(i,:,:),tempImgArray(ReferenceIndex,:,:));
                    else
                        NormImgArray(i,:,:)=adapthisteq(squeeze(tempImgArray(i,:,:)),"NumTiles",CLAHEParameters.NumTiles,'ClipLimit',CLAHEParameters.ClipLimit);
                    end
                end
                NewTrialPathArray(i)=fullfile(SavePath,strcat(name,"_Norm",".tif"));
                imwrite(squeeze(NormImgArray(i,:,:)),NewTrialPathArray(i));
                tempString= strcat("Save hist norm trial ",int2str(i));
                disp(tempString); 
            end

        end

    
end

