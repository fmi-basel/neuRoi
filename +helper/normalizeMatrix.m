function normMat = normalizeMatrix(mat)
mmin = min(mat(:));
mmax = max(mat(:));
if mmax-mmin
    normMat = (mat - mmin)/(mmax-mmin);
else
    normMat = ones(size(mat));
end
