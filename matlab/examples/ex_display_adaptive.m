% This example demonstrates a display-adaptive quality assessment using the
% PU21 transform. 
%
% The example shows how the quality of a distorted image changes with 
% the display peak brightness and ambient light level. Note that the
% reference image is shown on the same display, so the predicted quality
% shows how the distortions are masked by luminance and ambient light
% reflections. This example does not show how the peak brightness and 
% ambient light change the absolute image quality (e.g. as compared to an
% ideal viewing conditions). 

if ~exist( 'pu21_encoder', 'class' )
    addpath( fullfile( pwd, '..') );
end

% Load a reference image in the display-encoded colour space
I_ref = imread( 'wavy_facade.png' );

% Add noise to create a reference image
I_test_noise = imnoise( I_ref, 'gaussian', 0, 0.005 );

% The parameters of the display model
Y_peak_def = 200;
contrast_def = 1000; % 1000:1 contrast
E_ambient_def = 10; % Ambient light in lux


met_names = { 'PSNRY', 'SSIM', 'MSSSIM', 'VSI', 'FSIM' };

clf;
for kk=1:length(met_names)

    Y_peaks = [10 30 100 300 1000]; % Display peak luminance in cd/m^2
    Q = zeros(length(Y_peaks),1);
    for pp=1:length(Y_peaks)
        % Create a display model
        pu_dm = pu21_display_model_gog( Y_peaks(pp), contrast_def, [], E_ambient_def );
        Q(pp) = pu21_metric( I_test_noise, I_ref, met_names{kk}, pu_dm );
    end
    subplot( 2, length(met_names), kk );
    plot( Y_peaks, Q, 'o--' );
    set( gca, 'XScale', 'log' );
    set( gca, 'XTick', Y_peaks );
    xlabel( 'Display peak luminance [cd/m^2]' )
    title( met_names{kk} );
    drawnow

    E_ambs = [0.1 10 100 300 1000]; % Ambient light level in lux
    Q = zeros(length(E_ambs),1);
    for pp=1:length(E_ambs)
        % Create a display model
        pu_dm = pu21_display_model_gog( Y_peak_def, contrast_def, [], E_ambs(pp) );
        Q(pp) = pu21_metric( I_test_noise, I_ref, met_names{kk}, pu_dm );
    end
    subplot( 2, length(met_names), kk+length(met_names) );
    plot( E_ambs, Q, 'o--' );
    set( gca, 'XScale', 'log' );
    set( gca, 'XTick', E_ambs );
    xlabel( 'Ambient light [lux]' )
    title( met_names{kk} );
    drawnow
    
end


