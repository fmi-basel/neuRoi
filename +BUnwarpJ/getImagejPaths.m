function imagejPaths = getImagejPaths()
    currPath = mfilename('fullpath');
    [currDir, ~, ~] = fileparts(currPath);
    neuRoiDir = fullfile(currDir, '..');
    configFile = fullfile(neuRoiDir, 'config.ini');
    
    if ~exist(configFile, 'file')
        error(sprintf('Configuration file %s does not exists!', configFile))
    end
    
    ini = helper.IniConfig();
    ini.ReadFile();

    imagejPaths = ini.GetValues('[bunwarpj]');
end

