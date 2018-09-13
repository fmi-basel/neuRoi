function tform = registerImage(movingImg,fixedImg)
[optimizer, metric] = imregconfig('multimodal');
optimizer.InitialRadius = 0.009;
optimizer.Epsilon = 1.5e-4;
optimizer.GrowthFactor = 1.01;
optimizer.MaximumIterations = 300;
tform = imregtform(movingImg,fixedImg,'affine',optimizer, metric);
