% This simple example shows how to call PU21 metrics on SDR images
% assuming a certain display model.

if ~exist( 'pu21_encoder', 'class' )
    addpath( fullfile( pwd, '..') );
end

% Create test and reference images in the display-encoded colour space
I_ref = imread( 'wavy_facade.png' );
I_test_noise = imnoise( I_ref, 'gaussian', 0, 0.001 );
I_test_blur = imgaussfilt( I_ref, 2 );

% The parameters of the display model
Y_peak = 100; % Display peak luminance in cd/m^2
contrast = 1000; % 1000:1 contrast
E_ambient = 10; % Ambient light in lux

% Create a display model
pu_dm = pu21_display_model_gog( Y_peak, contrast, [], E_ambient );

PSNR_noise = pu21_metric( I_test_noise, I_ref, 'PSNR', pu_dm );
SSIM_noise = pu21_metric( I_test_noise, I_ref, 'SSIM', pu_dm );

PSNR_blur = pu21_metric( I_test_blur, I_ref, 'PSNR', pu_dm );
SSIM_blur = pu21_metric( I_test_blur, I_ref, 'SSIM', pu_dm );

fprintf( 1, 'Image with noise: PU21-PSNR = %g dB, PU21-SSIM = %g\n', PSNR_noise, SSIM_noise );
fprintf( 1, 'Image with blur: PU21-PSNR = %g dB, PU21-SSIM = %g\n', PSNR_blur, SSIM_blur );
