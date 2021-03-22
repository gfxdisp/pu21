function Q = pu21_metric( I_test, I_reference, metric, display_model )
% A convenience function for calling traditional (SDR) metrics on
% PU-encoded pixel values. This is useful for adapting traditional metrics
% to HDR images.
%
% Q = pu21_metric( I_test, I_reference, metric ) % for HDR images
% Q = pu21_metric( I_test, I_reference, metric, display_model ) % for SDR
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
% metric can be either 'PSNR', 'SSIM'. You can also pass a handle to a
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

if exist( 'dm', 'var' ) && ~isempty( display_model )
    % Simulate an SDR display if display model is provided
    L_test = display_model.forward( I_test );
    L_reference = display_model.forward( I_reference );
else
    % If no display model is provided, we assume an HDR image in absolute
    % units
    L_test = I_test;
    L_reference = I_reference;
end

% Convert abaolute linear values to PU value
pu21 = pu21_encoder();
P_test = pu21.encode( L_test );
P_reference = pu21.encode( L_reference );

if ischar( metric )
    switch metric
        case { 'PSNR', 'psnr' }
            Q = psnr( P_test, P_reference, 256 );
        case { 'SSIM', 'ssim' }
            % Note that we are passing floating point values, which are in the
            % range 0-256 for the luminance range 0.1 to 100 cd/m^2
            Q = ssim( P_test, P_reference, 'DynamicRange', 256);
        otherwise
            error( 'Unknown metric "%s"', metric );
    end
else
    Q = metric( P_test, P_reference );
end

end