function createRoiPatch(roi,parent)
% CREATEROIPATCH create a patch handle according to ROI position
% for visualization
% Usage: createRoiPatch(roi,parent)
% roi: the handle to a RoiFreehand object
% parent: the handle to the parent to which the patch is attached
    
if ~exist('parent', 'var')
    parent = gca;
end

position = roi.position;
roiPatch = patch(position(:,1),position(:,2),'y','Parent',parent);
set(roiPatch,'FaceAlpha',0.5)
set(roiPatch,'LineStyle','none');
set(roiPatch,'Tag',sprintf('roi_%04d',roi.id))
setappdata(roiPatch,'roiHandle',roi);
% moveit2(roiPatch)

