import torch

class pu21_encoder():
    """
    Transform absolute linear luminance values to/from the perceptually
    uniform (PU) space. This class is intended for adapting image quality 
    metrics to operator on the HDR content.
    
    Refer to the examples folder for examples how to use PU21 encoding
    with both HDR and SDR/LDR images. 
    
    The derivation of the PU21 encoding is explained in the paper: 
    
    R. Mantiuk and M. Azimi
    PU21: A novel perceptually uniform encoding for adapting existing
    quality metrics for HDR.
    Picture Coding Symposium 2021
    
    The new PU21 encoding improves on the older PU (or PU08) encoding,
    explained in: 
    
    Aydin TO, Mantiuk R, Seidel H-P. 
    Extending quality metrics to full luminance range images. 
    In: Human Vision and Electronic Imaging. Spie 2008. no. 68060B. 
    DOI: 10.1117/12.765095
    """

    def __init__(self,type = 'banding_glare'):
        """ 
        Create pu21_encoder or a given type (string), if the
        parameter is supplied.
        
        pu21 = pu21_encoder()
        pu21 = pu21_encoder( type )
        
        It is recommended that you use default type ('banding_glare')
        by skipping 'type' parameter. 
        """
        self.L_min = 0.005
        self.L_max = 10000
        self.type = type
        self.par = None
        if type == 'banding':
            self.par = [1.070275272, 0.4088273932, 0.153224308, 0.2520326168, 1.063512885, 1.14115047, 521.4527484]
        if type == 'banding_glare':
            self.par = [0.353487901, 0.3734658629, 8.277049286e-05, 0.9062562627, 0.09150303166, 0.9099517204, 596.3148142]
        if type == 'peaks':
            self.par = [1.043882782, 0.6459495343, 0.3194584211, 0.374025247, 1.114783422, 1.095360363, 384.9217577]
        if type == 'peaks_glare':
            self.par = [816.885024, 1479.463946, 0.001253215609, 0.9329636822, 0.06746643971, 1.573435413, 419.6006374]
        if self.par ==None:
            raise Exception("Unknow type: {}".format(type))
    
    def encode(self,Y):
        """
        Convert from linear (optical) values Y to encoded (electronic) values V
        
        V = encode(obj, Y)
        
        V is in the range from 0 to 1.
        Y is in the range from 0.005 to 10000. The values MUST be
            scaled in the absolute units (nits, cd/m^2).
        """
        epsilon = 1e-5
        if torch.any(Y<(self.L_min-epsilon)) or torch.any(Y>(self.L_max+epsilon)):
            print( 'Values passed to encode are outside the valid range' )
        
        
        Y = torch.clamp( Y, self.L_min, self.L_max); # Clamp the values
        p = self.par
        V = p[7] * (((p[1] + (p[2]*Y) **p[4])/ (1+(p[3]*Y)**p[4]))**p[5]-p[6])
        return V
    
    def decode(self, V):
        """
        Convert from encoded (electronic) values V into linear (optical) values Y
        
        Y = decode(obj, V)
        
        V is in the range from 0 to 1.
        Y is in the range from 0.005 to 10000
        """       
        p = self.par
        V_p = torch.maximum( V/p[7]+p[6], torch.tensor(0) )**(1/p[5])
        Y = (torch.maximum( V_p-p[1], torch.tensor(0) ) /(p[2]-p[3]*V_p))**(1/p[4])
        return Y