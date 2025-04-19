function normPath = normalizePath(inputPath, checkExists)
% normalizePath - Normalize any file or directory path
% 
% Syntax:
%   normPath = normalizePath(inputPath)
%   normPath = normalizePath(inputPath, checkExists)
%
% Description:
%   Converts a file or directory path to the native OS format,
%   resolves relative paths, and optionally checks if the path exists.
%
% Inputs:
%   inputPath    - Path to file or folder (string or char)
%   checkExists  - (optional) true to check if path exists [default: false]
%
% Output:
%   normPath     - Normalized, absolute path using OS-specific format

    if nargin < 2
        checkExists = false;
    end

    % Validate input
    if ~(ischar(inputPath) || isstring(inputPath))
        error('Input must be a string or character vector.');
    end
    inputPath = char(inputPath);  % ensure char

    % Expand user tilde (~) manually (MATLAB doesn't do this)
    if isunix || ismac
        if startsWith(inputPath, '~')
            homeDir = getenv('HOME');
            inputPath = fullfile(homeDir, inputPath(2:end));
        end
    end

    % Convert to absolute path
    if exist(inputPath, 'file') || exist(inputPath, 'dir')
        normPath = matlab.lang.makeValidName(inputPath);  % Ensure legal path (MATLAB var-safe)
        normPath = which(inputPath);  % Works for files or folders in path
        if isempty(normPath)
            normPath = fullfile(pwd, inputPath);  % fallback
        end
    else
        % Path doesn't exist — assume relative
        normPath = fullfile(pwd, inputPath);
    end

    % Normalize separators
    if ispc
        normPath = strrep(normPath, '/', '\');
    else
        normPath = strrep(normPath, '\', '/');
    end

    % Clean up any '..' or '.' parts
    normPath = char(java.io.File(normPath).getCanonicalPath());

    % Optionally check existence
    if checkExists && ~(isfile(normPath) || isfolder(normPath))
        error('The path "%s" does not exist.', normPath);
    end
end
