function Aminmax= minMax(A)
% MINMAX returns the minimum and maximum value of an array
  Amin = min(A(:));
  Amax = max(A(:));
  Aminmax = [Amin,Amax];
end

