classdef RoiGroup
    properties
        roiArrList
        currentIdx
    end

    methods
        function self = RoiGroup(roiArrList, nameList)
            self.roiArrList = roiArrList;
            self.nameList = nameList;
        end
        
        function addRoi(self)
            self.roiArrList{currentIdx};.addRoi();
        end
        
        function updateRoi(self, tag, roi)
        end
        
        function deleteRoi(self, tag)
        end
        
        

    end
end

