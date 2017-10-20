This experiment requires more RAM than other experiments: 12GB.

To view the reconstructed images, you can run the following scripts after `run.sh`:
```
ruby scripts/generateReconstructedImage.rb out/caltech/PIXELBRIGHTNESS.txt data/raw/caltech01.txt temp/caltech
ruby scripts/generateReconstructedImage.rb out/olivetti/PIXELBRIGHTNESS.txt data/raw/olivetti01.txt temp/olivetti
```

You can add the `--side` argument to generate the original and reconstructed side-by-side:
```
ruby scripts/generateReconstructedImage.rb out/caltech/PIXELBRIGHTNESS.txt data/raw/caltech01.txt temp/caltech --side
ruby scripts/generateReconstructedImage.rb out/olivetti/PIXELBRIGHTNESS.txt data/raw/olivetti01.txt temp/olivetti --side
```
