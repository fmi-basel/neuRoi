classdef RoiCollection
    properties
        roiArrList
        nameList
        currentIdx
        nArr
    end

    methods
        function self = RoiCollection(roiArrList, nameList)
            if length(roiArrList) ~= length(nameList)
                error('The input roiArr and name lists should have same length!')
            end
            
            self.roiArrList = roiArrList;
            self.nameList = nameList;
            self.nArr = length(roiArrList);
            self.currentIdx = 1;
        end
        
        function addRoi(self, roi, arrIdx)
            roiArr = self.roiArrList(arrIdx);
            roiArr.addRoi(roi);
        end
        
        function addRois(self, rois, arrIdx)
            roiArr = self.roiArrList(arrIdx);
            roiArr.addRois(rois);
        end
        
        function updateRoi(self, tag, roi, arrIdx)
            roiArr = self.roiArrList(arrIdx);
            roiArr.updateRoi(tag, roi);
        end
        
        function deleteRoi(self, tag, arrIdx)
            roiArr = self.roiArrList(arrIdx);
            roiArr.deleteRoi(tag);
        end
        
        function deleteRois(self, tags, arrIdx)
            roiArr = self.roiArrList(arrIdx);
            roiArr.deleteRois(tags);
        end
        
        function selectRois(self, arrIdxs, tagLists)
            for k=1:length(arrIdxs)
                self.roiArrList(arrIdxs(k)).selectRois(tagLists{k});
            end
        end
        
        function roiArr = getSelectedRois(self, arrIdx)
            roiList = self.roiArrList(arrIdx).getSelectedRois();
            roiArr = roiFunc.RoiArray('imageSize', self.roiArrList(arrIdx).imageSize,...
                                      'roiList', roiList);
        end
    end
end

