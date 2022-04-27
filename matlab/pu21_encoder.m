classdef pu21_encoder
    % Transform absolute linear luminance values to/from the perceptually
    % uniform (PU) space. This class is intended for adapting image quality 
    % metrics to operator on the HDR content.
    %
    % Refer to the examples folder for examples how to use PU21 encoding
    % with both HDR and SDR/LDR images. 
    %
    % The derivation of the PU21 encoding is explained in the paper: 
    %
    % R. Mantiuk and M. Azimi
    % PU21: A novel perceptually uniform encoding for adapting existing
    % quality metrics for HDR.
    % Picture Coding Symposium 2021
    %
    % The new PU21 encoding improves on the older PU (or PU08) encoding,
    % explained in: 
    %
    % Aydin TO, Mantiuk R, Seidel H-P. 
    % Extending quality metrics to full luminance range images. 
    % In: Human Vision and Electronic Imaging. Spie 2008. no. 68060B. 
    % DOI: 10.1117/12.765095
    
    properties
        par = [];
        L_min = 0.005; % The minimum linear value (luminance or radiance)
        L_max = 10000; % The maximum linear value (luminance or radiance)
    end    
    
    methods
        
        function obj = pu21_encoder( type )
            % Create pu21_encoder or a given type (string), if the
            % parameter is supplied.
            %
            % pu21 = pu21_encoder()
            % pu21 = pu21_encoder( type )
            %
            % It is recommended that you use default type ('banding_glare')
            % by skipping 'type' parameter. 
            
            if ~exist( 'type', 'var' )
                type = 'banding_glare';
            end
            
            % The paraeters were updated on 06/02/2020
            switch type
                case 'banding'
                    obj.par = [1.070275272, 0.4088273932, 0.153224308, 0.2520326168, 1.063512885, 1.14115047, 521.4527484];
                case 'banding_glare'
                    obj.par = [0.353487901, 0.3734658629, 8.277049286e-05, 0.9062562627, 0.09150303166, 0.9099517204, 596.3148142];
                case 'peaks'
                    obj.par = [1.043882782, 0.6459495343, 0.3194584211, 0.374025247, 1.114783422, 1.095360363, 384.9217577];
                case 'peaks_glare'
                    obj.par = [816.885024, 1479.463946, 0.001253215609, 0.9329636822, 0.06746643971, 1.573435413, 419.6006374];
                otherwise
                    error( 'Unknown type: %s', type );
            end
            
        end
        
        function V = encode(obj, Y)
            % Convert from linear (optical) values Y to encoded (electronic) values V
            %
            % V = encode(obj, Y)
            %
            % V is in the range from 0 to circa 600 (depends on the
            %   encoding used). 100 [nit] is mapped to 256 to mimic the
            %   input to SDR quality metrics. 
            % Y is in the range from 0.005 to 10000. The values MUST be
            %   scaled in the absolute units (nits, cd/m^2).
            
            epsilon = 1e-5;
            if any(Y(:)<(obj.L_min-epsilon)) || any(Y(:)>(obj.L_max+epsilon))
                warning( 'Values passed to encode are outside the valid range' );
            end
            
            Y = min(max(Y, obj.L_min), obj.L_max); % Clamp the values
            p = obj.par;
            V = max( p(7) * (((p(1) + p(2)*Y.^p(4))./(1+p(3).*Y.^p(4))).^p(5)-p(6)), 0 );
            
        end
        
        function Y = decode(obj, V)
            % Convert from encoded (electronic) values V into linear (optical) values Y
            %
            % Y = decode(obj, V)
            %
            % V is in the range from 0 to circa 600.
            % Y is in the range from 0.005 to 10000
            
            p = obj.par;
            V_p = max(V/p(7)+p(6),0).^(1/p(5));
            Y = (max( V_p-p(1), 0 )./(p(2)-p(3)*V_p)).^(1/p(4));
            
        end
        
    end
    
end