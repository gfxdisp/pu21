# This example shows how to run PU21 metrics on HDR images
import HDRutils
import os 
import pu21_metric
import pu21_display_model
import torch
import numpy as np
import scipy.ndimage as ndimage
import skimage
import cv2

I_ref = HDRutils.imread( os.path.join("..","matlab","examples",'wavy_facade.png' ))
# maxVal = np.iinfo(np.int16).max
I_ref = torch.tensor(I_ref.astype(np.int64))
# print(I_ref.mean())
# I_ref /=maxVal
# print(I_ref.mean())

# HDR images are often given in relative photometric units. They MUST be
# mapped to absolute amount of light emitted from the display. For that, 
# we map the peak value in the image to the peak value of the display:


# Add Gaussian noise of 20% contrast. Make sure all values are greater than
# 0.05.

I_test_noise = torch.maximum( I_ref + I_ref*torch.randn(I_ref.shape)*0.001,torch.tensor(0))

I_test_blur = cv2.GaussianBlur(I_ref.numpy().astype(np.float64), ksize=(0, 0), sigmaX=2, borderType=cv2.BORDER_REPLICATE)
I_test_blur = I_test_blur / np.iinfo(np.uint16).max
I_test_noise = I_test_noise / np.iinfo(np.uint16).max
print("noised ",I_test_blur.mean())
#I_test_blur = skimage.gaussian_filter(I_ref, sigma=2,mode = 'nearest',truncate=2.0)
Y_peak = 100
contrast = 1000
E_ambient = 10
pu_dm = pu21_display_model.pu21_display_model_gog( Y_peak, contrast, 2.2, E_ambient )

PSNR_noise = pu21_metric.pu21_metric( I_test_noise, I_ref, 'PSNR',pu_dm )
SSIM_noise = pu21_metric.pu21_metric( I_test_noise, I_ref, 'SSIM',pu_dm )


PSNR_blur = pu21_metric.pu21_metric( I_test_blur, I_ref, 'PSNR',pu_dm )
SSIM_blur = pu21_metric.pu21_metric( I_test_blur, I_ref, 'SSIM',pu_dm )

print('Image with noise: PSNR = {} dB, SSIM = {}'.format( PSNR_noise, SSIM_noise) )
print('Image with blur: PSNR = {} dB, SSIM = {}'.format( PSNR_blur, SSIM_blur) )
