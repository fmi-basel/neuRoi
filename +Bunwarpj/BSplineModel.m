classdef BSplineModel
    properties
        image;  % Original image stored as a matrix
        interpolant;  % Interpolation object
    end

    methods
        function obj = BSplineModel(image)
            % Constructor: Initialize B-Spline model
            if nargin > 0
                obj.image = double(image);  % Convert to double for precision
                [h, w] = size(image);
                
                % Create interpolation grid
                [X, Y] = meshgrid(1:w, 1:h);
                
                % Use griddedInterpolant for B-Spline interpolation
                obj.interpolant = griddedInterpolant(Y, X, obj.image, 'spline', 'nearest');
            end
        end

        function prepareForInterpolation(obj, x, y, ~)
            % Placeholder function (Java version initializes something, but unnecessary here)
        end

        function value = interpolateI(obj, x, y)
            % Perform B-Spline interpolation at (x, y)
            value = obj.interpolant(y, x);  % Use MATLAB's built-in interpolation
        end
    end
end
