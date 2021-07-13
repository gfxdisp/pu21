# This example shows how to run PU21 metrics on HDR images
import HDRutils
import os 
import pu21_metric
import torch
import scipy.ndimage as ndimage

I_ref = HDRutils.imread( os.path.join("..","matlab","examples",'nancy_church.hdr' ))
I_ref = torch.tensor(I_ref)
L_peak = 4000 # Peak luminance of an HDR display

# HDR images are often given in relative photometric units. They MUST be
# mapped to absolute amount of light emitted from the display. For that, 
# we map the peak value in the image to the peak value of the display:

I_ref = I_ref/torch.max(I_ref) * L_peak

# Add Gaussian noise of 20% contrast. Make sure all values are greater than
# 0.05.

I_test_noise = torch.maximum(I_ref + I_ref*torch.randn(I_ref.shape)*0.2, torch.tensor(0.05) )



PSNR_noise = pu21_metric.pu21_metric( I_test_noise, I_ref, 'PSNR' )
SSIM_noise = pu21_metric.pu21_metric( I_test_noise, I_ref, 'SSIM' )

print('Image with noise: PSNR = {} dB, SSIM = {}'.format( PSNR_noise, SSIM_noise) )
print(I_ref.shape)
I_test_blur = ndimage.gaussian_filter(I_ref, sigma=(3, 3, 3), order=0)
#I_test_blur = imgaussfilt( I_ref, 3 )

PSNR_noise = pu21_metric.pu21_metric( I_test_blur, I_ref, 'PSNR' )
SSIM_noise = pu21_metric.pu21_metric( I_test_blur, I_ref, 'SSIM' )
print('Image with blur: PSNR = {} dB, SSIM = {}'.format( PSNR_noise, SSIM_noise) )
