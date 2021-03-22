% This example shows how to run PU21 metrics on HDR images

if ~exist( 'pu21_encoder', 'class' )
    addpath( fullfile( pwd, '..') );
end

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
