function AUnit = convertToUint(A,depth,zlim)
% CONVERTTOUNIT convert matrix to unsigned int
%     Args:
%         A (array): matrix containing data to be converted.
%         depth (scalar, optional): depth of the uint, 8 for unit8,
%         16 for unit. Default 8.
%         zlim (1x2 vector, optional): min and max value for
%         normalizing the input matrix. Default min and matrix of
%         the matrix.
%     Returns:
%         AUnit (array): matrix that is converted to unit.
if ~exist('depth','var')
    depth = 8;
end

if ~exist('zlim','var')
    zlim = [min(A(:)), max(A(:))];
end

if depth == 16
    AUnit = uint16((2^16 -1)* Anorm);
else
    AUnit = uint8(255*Anorm);
end
