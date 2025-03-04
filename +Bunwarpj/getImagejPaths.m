function imagejPaths = getImagejPaths()
    [fdir, ~, ~] = fileparts(mfilename('fullpath')); 
    configFile = fullfile(fdir, '..', 'config.ini');
    ini = helper.IniConfig();
    ini.ReadFile(configFile)
    
    imagejPaths = {};
    imagejPaths{1} = ini.GetValues('bunwarpj', 'path1');
    imagejPaths{2} = ini.GetValues('bunwarpj', 'path2');
    imagejPaths{3} = ini.GetValues('bunwarpj', 'path3');
    imagejPaths{4} = ini.GetValues('bunwarpj', 'path4');
end

