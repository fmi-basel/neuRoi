function imagejPaths = getImagejPaths()
    imagejDir = '/home/hubo/Software/Fiji.app/';
    imagejPaths = {};
    imagejPaths{end+1} = fullfile(imagejDir, 'plugins/bUnwarpJ_-2.6.13.jar');
    imagejPaths{end+1} = fullfile(imagejDir, 'jars/ij-1.53q.jar');
    imagejPaths{end+1} = fullfile(imagejDir, 'plugins/mpicbg_-1.4.1.jar');
    imagejPaths{end+1} = fullfile(imagejDir, 'jars/mpicbg-1.4.1.jar');

