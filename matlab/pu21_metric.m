function Q = pu21_metric( I_test, I_reference, metric, display_model, options )
arguments
    I_test { isimage(I_test) }
    I_reference { isimage(I_reference) }
    metric = 'PSNR'
    display_model = []
    options.crf_correction logical = false
end
% A convenience function for calling traditional (SDR) metrics on
% PU-encoded pixel values. This is useful for adapting traditional metrics
% to HDR images.
%
% Q = pu21_metric( I_test, I_reference, metric ) % for HDR images
% Q = pu21_metric( I_test, I_reference, metric, display_model ) % for SDR
% Q = pu21_metric( ..., 'crf_correction', true ) % SI-HDR evaluation
%
% When no display model is passed, I_test and I_reference must be provided
% as ABSOLUTE linear colour or luminance values. If unsure what those values
% are, please refer to the paper [1].
%
% When display model is passed, I_test and I_reference contain images in
% display-encoded sRGB colour space or luma (standard images). If images
% are stored as floating point values, the values must be in the range 0-1.
% If they are stored as integers, they must be in the range
% from 0 to maxint(class(I)).
%
% display_model is an object of the class pu21_display_model_gog. Check
% exaples/ex_sdr_images.m on how to create an object of this class.
%
% metric agument must be one of:
% 'PSNR' - Peak Signal-to-Noise Ratio
% 'PSNRY' - Peak Signal-to-Noise Ratio on luminance
% 'SSIM' - Structural Similarity Index (on luminance). 
% 'MSSSIM' - Multi-Scale Structural Similarity Index (on luminance). 
% 'FSIM' - Feature SIMilarity index
% 'VSI' - Visual Saliency based Index
%
% Note that an RGB image wll be converted to luminance before running any
% luminance-only metric, such as SSIM or MSSSIM. 
%
% You can also pass as a 'metric' a handle to a 
% function Q = fun(I_test, I_referece). The function should expect both
% images to be stored as floating point numbers and the typical range from
% 0 to 255. The range of values can be higher for bright HDR images or
% bright SDR displays.
%
% [1] 1. Mantiuk RK.
% Practicalities of predicting quality of high dynamic range images and video.
% In: 2016 IEEE International Conference on Image Processing (ICIP), p. 904–8.
% https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2016prac_hdr_metrics.pdf
% http://dx.doi.org/10.1109/ICIP.2016.7532488


% If images are stored as intigers, convert to a single precision floating
% point between 0 and 1.
if ~isfloat(I_test)
    I_test = single(I_test)/single(intmax(class(I_test)));
end
if ~isfloat(I_reference)
    I_reference = single(I_reference)/single(intmax(class(I_reference)));
end

if ~isempty( display_model )
    % Simulate an SDR display if display model is provided
    L_test = display_model.forward( I_test );
    L_reference = display_model.forward( I_reference );
else
    % If no display model is provided, we assume an HDR image in absolute
    % units
    L_test = I_test;
    L_reference = I_reference;
end

if options.crf_correction
    if ismatrix(L_test)
        error( 'crf_correction can be used with color images only.')
    end

    L_test = crf_correction( L_test, L_reference );
end

MET = struct();
MET.PSNR.only_lum = false;
MET.PSNR.func = @(T,R) psnr( T, R, 256 );

MET.PSNRY.only_lum = true;
MET.PSNRY.func = @(T,R) psnr( T, R, 256 );

MET.SSIM.only_lum = true;
MET.SSIM.func = @(T,R) ssim( T, R, 'DynamicRange', 256);            

MET.MSSSIM.only_lum = true;
MET.MSSSIM.func = @(T,R) multissim( T, R, 'DynamicRange', 256);            

MET.VSI.only_lum = false;
MET.VSI.func = @(T,R) m_vsi( T, R );            

MET.FSIM.only_lum = false;
MET.FSIM.func = @(T,R) m_fsim( T, R );

pu21 = pu21_encoder();

if ischar( metric )
    metric = upper(metric);
    if isfield( MET, metric )
        % Convert abaolute linear values to PU values

        if ndims(L_test)==3 && MET.(metric).only_lum
            % Convert RGB image to luminance image
            L_test = get_luminance( L_test );
            L_reference = get_luminance( L_reference );
        end

        P_test = pu21.encode( L_test );
        P_reference = pu21.encode( L_reference );

        Q = MET.(metric).func(P_test,P_reference);
    else
        error( 'Unknown metric "%s"', metric );
    end

else
    % Convert abaolute linear values to PU values
    P_test = pu21.encode( L_test );
    P_reference = pu21.encode( L_reference );
    Q = metric( P_test, P_reference );
end

end

function val = isimage(I)
val = isnumeric(I) && (ndims(I)==2 || (ndims(I)==3 && size(I,3)==3));
end

function Y = get_luminance( img )
% Return 2D matrix of luminance values for 3D matrix with an RGB image

Y = img(:,:,1) * 0.212656 + img(:,:,2) * 0.715158 + img(:,:,3) * 0.072186;
end