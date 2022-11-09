import os
import sys
import argparse
from glob import glob
from tifffile import imread
from csbdeep.io import save_tiff_imagej_compatible
from csbdeep.utils import normalize
from stardist.models import StarDist2D

def predict_mask_rgb(indir, outdir, model_dir, model_name='stardist'):
    model = StarDist2D(None, name=model_name, basedir=model_dir)
    file_list = sorted(glob(os.path.join(indir, '*.tif')))
    X = list(map(imread, file_list))
    for k in range(len(file_list)):
        filename = file_list[k]
        axis_norm = (0,1,2) # normalize channels jointly
        x = normalize(X[k],1,99.8,axis=axis_norm)
        labels, details = model.predict_instances(x, n_tiles=model._guess_n_tiles(x), show_tile_progress=False)
        mask_filename = 'mask_' + os.path.basename(filename)
        mask_file = os.path.join(outdir, mask_filename)
        save_tiff_imagej_compatible(mask_file, labels, axes='YX')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("indir", help="Input directory for anatomy images")
    parser.add_argument("outdir", help="Onput directory for predicted mask images")
    args = parser.parse_args()
    model_dir = 'models/models-mergedRGB/models_Bo_200Epoche_aggrAugm'
    predict_mask_rgb(args.indir, args.outdir, model_dir)
