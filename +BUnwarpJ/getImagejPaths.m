function imagejPaths = getImagejPaths()
    currPath = mfilename('fullpath');
    [currDir, ~, ~] = fileparts(currPath);
    neuRoiDir = fullfile(currDir, '..');
    configFile = fullfile(neuRoiDir, 'config.ini');
    
    if ~exist(configFile, 'file')
        error(sprintf('Configuration file %s does not exists!', configFile))
    end
    
    ini = helper.IniConfig();
    ini.ReadFile(configFile);

    ijPath = ini.GetValues('[bunwarpj]', 'path');

    imagejPaths = {};

    imagejPaths{1} = dir(fullfile(ijPath, 'plugins', 'bUnwarpJ_-*.jar'));

    if isempty(imagejPaths{1})
        error('bUnwarpJ not found in imagej.')
    end

    imagejPaths{2} = dir(fullfile(ijPath, 'plugins', 'mpicbg_*.jar'));

    if isempty(imagejPaths{2})
        error('mpicbg plugin not found in imagej.')
    end

    imagejPaths{3} = dir(fullfile(ijPath, 'jars', 'ij-*.jar'));

    if isempty(imagejPaths{3})
        error('ij not found in imagej.')
    end

    imagejPaths{4} = dir(fullfile(ijPath, 'jars', 'mpicbg-*.jar'));

    if isempty(imagejPaths{4})
        error('mpicbg jar not found in imagej.')
    end

    imagejPaths = cellfun(@(x) fullfile(x.folder, x.name),...
        imagejPaths, 'UniformOutput', false);
end

