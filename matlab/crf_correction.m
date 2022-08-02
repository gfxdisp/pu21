%CRF_CORRECTION Correction of CRF based on reference HDR image
%   [It,x] = crf_correction(Ir, Igt, deg, lambda, ptf_type, cspace, normalize)
%   aligns the image Ir to the reference HDR image Igt.
%
%   'Ir'        - Input image for correction
%   'Igt'       - Reference HDR image
%   'deg'       - Degree of polynomial
%   'lambda'    - Regularization, penalizing large coefficients
%   'ptf_type'  - Non-linear transformation ('log', 'pq', or 'linear')
%   'cspace'    - Color space ('rgb' or 'luv')
%   'normalize' - Normalize input images (for images not properly scaled
%                 to absolute luminace)
%
% Examples: [It,x] = crf_correction(I, Igt);
%           [It,x] = crf_correction(I, Igt, 3, 0.01, 'pq', 'luv', 0);

function [It,x] = crf_correction(Ir, Igt, varargin)
    args = {3,0.01,'pq','luv',0};  % default values
    args(1:nargin-2) = varargin;
    
    params = struct;
    params.L_min = 0.005;
    params.L_max = 1e4;
    params.deg = args{1};        % degree of polynomial
    params.lambda = args{2};     % regularization strength
    params.ptf_type = args{3};   % 'pq' or 'log', otherwise linear
    params.cspace = args{4};     % 'rgb' or 'luv'
    params.normalize = args{5};  % perform normalization (if input 
                                 % images are not properly calibrated
                                 % to absolute luminance, normalization
                                 % and an approximate calibration can
                                 % be performed)
    params.sc = 500;             % pre-scaling (for approx. calibration)
    
    % approximate scaling to absolute luminance (anchoring image median
    % to the params.sc value)
    if params.normalize
        scale_gt = median(Igt(:));
        Igt = params.sc*Igt/scale_gt;
        Ir = params.sc*Ir/median(Ir(:));
    end
    Igt = max(Igt,params.L_min); Ir = max(Ir,params.L_min);

    % correction in RGB
    if strcmpi(params.cspace, 'rgb')
        [It,x] = corr_opt(Ir, Igt, params);
    
    % correction in Luv
    elseif strcmpi(params.cspace, 'luv')
        Ir_luv = rgb2luv(Ir);
        Igt_luv = rgb2luv(Igt);
        
        % correction of luminance, without regularization
        lambda = params.lambda;
        params.lambda = 0;
        [It_l,x1] = corr_opt(Ir_luv(:,:,1), Igt_luv(:,:,1), params);
        
        % correction of uv, in linear domain with regularization
        params.ptf_type = 'lin';
        params.lambda = lambda;
        [It_uv,x2] = corr_opt(Ir_luv(:,:,2:3), Igt_luv(:,:,2:3), params);
        
        x = {x1,x2};
        It_luv = zeros(size(Ir_luv));
        It_luv(:,:,1) = It_l;
        It_luv(:,:,2:3) = It_uv;
        It = luv2rgb(It_luv);
    end
    
    if params.normalize
        It = scale_gt*It/params.sc;
    end
end

% Correction
function [It,W] = corr_opt(Ir, Igt, params)
    zz = size(Ir,3);
    y = Igt; x = Ir;

    % non-linear transform
    y = ptf(y, params.ptf_type, params.L_max, 1);
    x = ptf(x, params.ptf_type, params.L_max, 1);

    % matrix formulation of the optimization
    Y = reshape(y, [size(y,1)*size(y,2),zz]);
    X = lin_matrix(x, params.deg);
    
    % identity mapping (for regularization)
    W0 = zeros(size(X,2),zz);
    W0(end-zz:end-1,:) = eye(zz);
    
    % least squares fit, with regularization
    sc = params.lambda*size(X,1)/size(X,2);
    W = (X'*X + sc*eye(size(X,2)))^-1 * (X'*Y + sc*W0);
    
    % correct the image with the fitted polynomial
    It = reshape(X*W,size(Ir));
    It = max(It,ptf(params.L_min,params.ptf_type,params.L_max,1));
    It = ptf(It,params.ptf_type,params.L_max,0);
end

% Non-linear forward and inverse transform, PQ or log10
function y = ptf(x, ptf_type, L_max, forw)
    m = 78.8438; n = 0.1593;
    c1 = 0.8359; c2 = 18.8516; c3 = 18.6875;
    
    y = x;

    if forw
        if strcmpi(ptf_type, 'pq')
            Lp = (x/L_max).^n;
            y = ((c1 + c2*Lp) ./ (1 + c3*Lp)).^m;
        elseif strcmpi(ptf_type, 'log')
            y = log10(x);
        end
    else
        if strcmpi(ptf_type, 'pq')
            Lp = (c1 - x.^(1/m)) ./ (c3*x.^(1/m) - c2);
            y = L_max * Lp.^(1/n);
        elseif strcmpi(ptf_type, 'log')
            y = 10.^x;
        end
    end
end

% RGB to Luv
function luv = rgb2luv(rgb)
    rgb2xyzMat = [0.412424, 0.357579, 0.180464;
                  0.212656, 0.715158, 0.072186;
                  0.019332, 0.119193, 0.950444];

    % RGB -> XYZ
    xyz = zeros(size(rgb));
    for c = 1:3
        xyz(:,:,c) = max(min(rgb2xyzMat(c,1)*rgb(:,:,1) + ...
                             rgb2xyzMat(c,2)*rgb(:,:,2) + ...
                             rgb2xyzMat(c,3)*rgb(:,:,3), 100000000.0), 0.0001);
    end

    % XYZ -> LUV
    s = sum(xyz, 3);
    x = xyz(:,:,1)./s;
    y = xyz(:,:,2)./s;

    luv = zeros(size(rgb));
    luv(:,:,1) = xyz(:,:,2);
    luv(:,:,2) = 4.0*x./(-2.0*x + 12.0*y + 3.0) * 410/255.0;
    luv(:,:,3) = 9.0*y./(-2.0*x + 12.0*y + 3.0) * 410/255.0;
end

% Luv to RGB
function rgb = luv2rgb(luv)
    rgb2xyzMat = [0.412424, 0.357579, 0.180464;
                  0.212656, 0.715158, 0.072186;
                  0.019332, 0.119193, 0.950444];

    xyz2rgbMat = rgb2xyzMat^-1;

    % LUV -> XYZ
    L = luv(:,:,1);
    u = luv(:,:,2)*255.0/410.0;
    v = luv(:,:,3)*255.0/410.0;

    x = 9.0*u ./ (6.0*u - 16.0*v + 12.0);
    y = 4.0*v ./ (6.0*u - 16.0*v + 12.0);

    Y = max(min(L, 1e8), 1e-4);
    X = max(min((x./y) .* L, 1e8), 1e-4);
    Z = max(min(((1.0-x-y)./y) .* L, 1e8), 1e-4);

    % XYZ --> RGB
    rgb = zeros(size(luv));
    for c = 1:3
        rgb(:,:,c) = max(0, xyz2rgbMat(c,1)*X + xyz2rgbMat(c,2)*Y + xyz2rgbMat(c,3)*Z);
    end
end

% Setup pixel-matrix from image, for matrix multiplication with polynomial
% coefficients. Cross-channel dependencies can be modeled if the image has
% multiple channels.
function M = lin_matrix(I,deg)
    s = size(I,1)*size(I,2);
    zz = size(I,3);
    
    M_ = reshape(I, [s,zz]);
    M = [];
    
    % add cross-channel dependencies to matrix
    if zz > 1
        for i = 1:zz-1
            for j = i+1:zz
                M = [M, M_(:,i).*M_(:,j)];
            end
        end
    end
    
    % add linear and constant term to matrix
    M = [M, M_, ones(s,1)];
    
    % add polynomial indeterminates to matrix
    for d = 2:deg
        M = [M_.^d, M]; 
    end
end
