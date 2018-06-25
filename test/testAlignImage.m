imgA = imread('cameraman.tif');
imgB = imtranslate(imgA,[15, 25]);

imgA = imgA(30:229,30:229);
imgB = imgB(30:229,30:229);

offset = alignImage(imgA,imgB)
imgC = imtranslate(imgB,-offset);

figure
imshow(imgA)
title('A')


figure
imshow(imgB)
title('B')

figure
imshow(imgC)
title('C')


