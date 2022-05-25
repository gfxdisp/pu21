# This example shows how to run PU21 metrics on HDR images
import HDRutils
import os 
import pu21_metric
import torch
import scipy.ndimage as ndimage
import numpy as np
import cv2
# in python

I_ref = HDRutils.imread( os.path.join("..","matlab","examples",'nancy_church.hdr' ))
I_ref = torch.tensor(I_ref)
print(I_ref.mean())
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

def matlab_style_gauss2D(shape=(3,3),sigma=0.5):
    """
    2D gaussian mask - should give the same result as MATLAB's
    fspecial('gaussian',[shape],[sigma])
    """
    m,n = [(ss-1.)/2. for ss in shape]
    y,x = np.ogrid[-m:m+1,-n:n+1]
    h = np.exp( -(x*x + y*y) / (2.*sigma*sigma) )
    h[ h < np.finfo(h.dtype).eps*h.max() ] = 0
    sumh = h.sum()
    if sumh != 0:
        h /= sumh
    return h
I_test_blur = cv2.GaussianBlur(I_ref.numpy(), ksize=(0, 0), sigmaX=3, borderType=cv2.BORDER_REPLICATE)
 #= torch.conv2d(I_ref.permute(2,1,0),torch.tensor(matlab_style_gauss2D()))
#I_test_blur = ndimage.gaussian_filter(I_ref, sigma=3, order=0)
#I_test_blur = imgaussfilt( I_ref, 3 )

PSNR_noise = pu21_metric.pu21_metric( I_test_blur, I_ref, 'PSNR' )
SSIM_noise = pu21_metric.pu21_metric( I_test_blur, I_ref, 'SSIM' )
print('Image with blur: PSNR = {} dB, SSIM = {}'.format( PSNR_noise, SSIM_noise) )
