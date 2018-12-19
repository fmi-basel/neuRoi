function AUnit = convertToUint(A,depth)
if ~exist('depth','var')
    depth = 8;
end

if depth == 16
    AUnit = uint16((2^16 -1)* mat2gray(A));
else
    AUnit = uint8(255*mat2gray(A));
end

