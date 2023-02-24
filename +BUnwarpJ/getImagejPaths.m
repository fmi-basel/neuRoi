function imagejPaths = getImagejPaths()
    currPath = mfilename('fullpath');
    [currDir, ~, ~] = fileparts(currPath);
    neuRoiDir = fullfile(currDir, '..');

    ini = helper.IniConfig();
    ini.ReadFile(fullfile(neuRoiDir, 'config.ini'));

    imagejPaths = ini.GetValues('[bunwarpj]');
end

