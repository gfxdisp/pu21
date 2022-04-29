# PU21 
## Perceptual Uniform encoding for high dynamic range image and video quality assessment 

This is 2021 revision of the method for encoding high dynamic range images so that their quality can be evaluated with simple metrics, such as PSNR or SSIM. 

![PU usage diagram](https://raw.githubusercontent.com/gfxdisp/pu21/images/images/pu_diagram.png)

Because linear colour values used for high dynamic range images are not perceptual uniform, HDR pixel values must not be directly used with the metrics intended for standard dynamic range (SDR) images (such as PSNR, SSIM, MS-SSIM). PU21 encodes absolute linear RGB colour values so that they are more perceptually uniform and can be used with SDR metrics. To properly account for the sensitivity of the visual system at a given luminance level, the linear colour values must be mapped to absolute values (emitted from a reference display) before they can be passed to the PU21 encoding. 

Currently only Matlab code is available. However, since the encoding involves a single equation, it can be easily ported to other languages. The encoding is implemented [here](https://github.com/gfxdisp/pu21/blob/main/matlab/pu21_encoder.m). Please use only the `banding_glare` variant. 

## CRF correction - evaluation of single-image HDR reconstruction methods

The repository includes CRF correction code, which we recommend to use when evaluation single-image high-dynamic-range (SI-HDR) reconstruction methods, or any methods, for which the reproduction of details and structure is more important than the reproduction of tones and colours. See [ex_sihdr.m](https://github.com/gfxdisp/pu21/blob/main/matlab/examples/ex_sihdr.m) for an example how to use CRF correction to compare SI-HDR methods. The details of this technique can be found in the SIGGRAPH paper “Comparison of Single Image HDR Reconstruction Methods — the Caveats of Quality Assessment.” (see the full reference below).

# Example

This example shows how to run PU21 metrics on HDR images

```matlab
I_ref = hdrread( 'nancy_church.hdr' );

L_peak = 4000; % Peak luminance of an HDR display

% HDR images are often given in relative photometric units. They MUST be
% mapped to absolute amount of light emitted from the display. For that, 
% we map the peak value in the image to the peak value of the display:
I_ref = I_ref/max(I_ref(:)) * L_peak;

% Add Gaussian noise of 20% contrast. Make sure all values are greater than
% 0.05.
I_test_noise = max( I_ref + I_ref.*randn(size(I_ref))*0.2, 0.05 );

I_test_blur = imgaussfilt( I_ref, 3 );

PSNR_noise = pu21_metric( I_test_noise, I_ref, 'PSNR' );
SSIM_noise = pu21_metric( I_test_noise, I_ref, 'SSIM' );

PSNR_blur = pu21_metric( I_test_blur, I_ref, 'PSNR' );
SSIM_blur = pu21_metric( I_test_blur, I_ref, 'SSIM' );

fprintf( 1, 'Image with noise: PSNR = %g dB, SSIM = %g\n', PSNR_noise, SSIM_noise );
fprintf( 1, 'Image with blur: PSNR = %g dB, SSIM = %g\n', PSNR_blur, SSIM_blur );

```

More examples can be found in the [example](https://github.com/gfxdisp/pu21/tree/main/matlab/examples) folder. 

# Metrics

The current version includes the following metrics:
* PSNR (colour)
* PSNRY (luminance)
* SSIM (luminance)
* MS-SSIM (luminance)
* FSIM (colour)
* VSI (colour)

The code of FSIM and VSI is copyrighted by the corresponding authors and is included in this repository for convenience. 

# Conference talk video

You can watch the [video](https://youtu.be/C2tafNbpwtY) recorded for the Picture Coding Symposium (2021), which explains how to use the PU21 and how it was derived.

# Other metrics

Alternative metrics for assessing the quality of high dynamic range images and video:

[FovVideoVDP](https://github.com/gfxdisp/FovVideoVDP) - Foveated Video Visual Difference Predictor

[HDR-VDP-2 / HDR-VDP-3](http://hdrvdp.sourceforge.net/) - Visual Difference Predictor for High Dynamic Range Images

# References

If you use PU21 encoding in your research, please cite the following paper, which explains the derivation of PU21:

> PU21: A novel perceptually uniform encoding for adapting existing quality metrics for HDR.
> Rafał K. Mantiuk and Maryam Azimi
> In: Picture Coding Symposium 2021

> [PDF](https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2021_PU21.pdf)

The new PU21 encoding improves on the older PU (or PU08) encoding, which is explained in: 

> Extending quality metrics to full luminance range images. 
> Tunç O. Aydın, Rafał Mantiuk and Hans-Peter Seidel
> In: Human Vision and Electronic Imaging. Spie 2008. no. 68060B. 

> [PDF](https://www.cl.cam.ac.uk/~rkm38/pdfs/aydin08eqmflri.pdf)
> [http://dx.doi.org/10.1117/12.765095](http://dx.doi.org/10.1117/12.765095) 

The CRF correction is explained in:

> Comparison of Single Image HDR Reconstruction Methods — the Caveats of Quality Assessment.
> Hanji, Param, Rafał K. Mantiuk, Gabriel Eilertsen, Saghi Hajisharif, and Jonas Unger. 
> In SIGGRAPH ’22 Conference Proceedings. 2022. https://doi.org/10.1145/3528233.3530729.

Discussion of the evaluation of quality of HDR images is discussed in:

> Practicalities of predicting quality of high dynamic range images and video
> Rafał K. Mantiuk.
> In: Proc. of IEEE International Conference on Image Processing (ICIP'16), pp. 904-908, 2016

> [PDF](https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2016prac_hdr_metrics.pdf)
> [http://dx.doi.org/10.1109/ICIP.2016.7532488](http://dx.doi.org/10.1109/ICIP.2016.7532488) 
