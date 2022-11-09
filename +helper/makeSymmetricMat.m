function B = makeSymmetricMat(A)
B = (A+A') - eye(size(A,1)).*diag(A);
