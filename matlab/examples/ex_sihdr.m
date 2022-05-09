% Example: Evaluation of a single-image high dynamic range (SI-HDR)
% reconstruction methods
% 
% This example demonstrates how to use a CRF correction, which reduces
% differences in tones and colours between reference and test images. It
% should be used when the quality assessment is meant to detect structural
% differences rather than tone and colour differences, for example, when
% assessing SI-HDR methods. The metrics tend to correlate much better with
% subjective judgements when the CRF correction is used for evaluation of
% SI-HDR methods. 
%
% The technique and it advantages was demonstrated in the paper:
%
% Hanji, Param, Rafał K. Mantiuk, Gabriel Eilertsen, Saghi Hajisharif, and Jonas Unger. 
% “Comparison of Single Image HDR Reconstruction Methods — the Caveats of Quality Assessment.” 
% In SIGGRAPH ’22 Conference Proceedings. Association for Computing Machinery, 2022. 
% https://doi.org/10.1145/3528233.3530729.
%
% Please cite the paper above if you use CRF correction in your evaluation.

if ~exist( 'pu21_encoder', 'class' )
    addpath( fullfile( pwd, '..') );
end

I_ref = hdrread( 'nancy_church.hdr' );

L_peak = 4000; % Peak luminance of an HDR display

% HDR images are often given in relative photometric units. They MUST be
% mapped to absolute amount of light emitted from the display. For that, 
% we map the peak value in the image to the peak value of the display:
I_ref = I_ref/max(I_ref(:)) * L_peak;

% To simulate the result of a SI-HDR method A, we clip 5% of the brightest
% pixels + add a bit of noise. 
I_noise = randn(size(I_ref)).*I_ref*0.02;
I_A = min( I_ref+I_noise, prctile( I_ref(:), 95 ) );

% To simulate the result of a SI-HDR method B, we apply a tone-curve but
% clip no pixels
tc = @(L, b, L_m) (L.^b ./ (L_m^b+L.^b));
I_B = L_peak * tc(I_ref+I_noise, 0.5, 300);

Q_A = pu21_metric( I_A, I_ref, 'FSIM' );
Q_B = pu21_metric( I_B, I_ref, 'FSIM' );

% Enable CRF correction when evaluation SI-HDR methods
Q_A_corr = pu21_metric( I_A, I_ref, 'FSIM', 'crf_correction', true );
Q_B_corr = pu21_metric( I_B, I_ref, 'FSIM', 'crf_correction', true );

% Note that without the CRF correction, the quality drops significanly for
% method B, affected by tone-curve. When CRF correction is enabled, almost
% perfect quality is reported for method B. 
fprintf( 1, 'Quality (FSIM) of method A: 5%% of the brightest pixels clipped\n\tno correction: %g, \twith correction: %g\n', Q_A, Q_A_corr );
fprintf( 1, 'Quality (FSIM) of method B: tone curve applied\n\tno correction: %g, \twith correction: %g\n', Q_B, Q_B_corr );
