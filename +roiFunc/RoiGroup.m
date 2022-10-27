classdef RoiGroup
    properties
        roiArrList
        nameList
        currentArrIdx
    end

    methods
        function self = RoiGroup(roiArrList, nameList)
            self.roiArrList = roiArrList;
            self.nameList = nameList;
        end
        
        function addRoi(self, roi)
            self.roiArrList{currentIdx}.addRoi(roi);
        end
        
        function updateRoi(self, tag, roi)
            self.roiArrList{currentIdx}.addRoi(tag, roi);
        end
        
        function deleteRoi(self, tag)
            self.roiArrList{currentIdx}.deleteRoi(tag, roi);
        end

    end
end

