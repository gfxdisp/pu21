% Plot the quality degradation with noise for all supported metrics

if ~exist( 'pu21_encoder', 'class' )
    addpath( fullfile( pwd, '..') );
end

% Load a reference image in the display-encoded colour space
I_ref = imread( 'wavy_facade.png' );

% The parameters of the display model
Y_peak = 100; % Display peak luminance in cd/m^2
contrast = 1000; % 1000:1 contrast
E_ambient = 10; % Ambient light in lux

% Create a display model
pu_dm = pu21_display_model_gog( Y_peak, contrast, [], E_ambient );

met_names = { 'PSNR', 'PSNRY', 'SSIM', 'MSSSIM', 'VSI', 'FSIM' };

clf;
for kk=1:length(met_names)

    noise_levs = [0.001 0.01 0.05 0.1];
    Q = zeros(length(noise_levs),1);
    for nn=1:length(noise_levs)
        I_test_noise = imnoise( I_ref, 'gaussian', 0, noise_levs(nn) );
        Q(nn) = pu21_metric( I_test_noise, I_ref, met_names{kk}, pu_dm );
    end
    subplot( 2, ceil(length(met_names)/2), kk );
    plot( noise_levs, Q, 'o--' );
    xlabel( 'Noise amplitude' )
    title( met_names{kk} );
    drawnow
end


