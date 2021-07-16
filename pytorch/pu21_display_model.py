#%%
import torch
pi = torch.acos(torch.zeros(1)).item() * 2
#%%
class pu21_display_model_gog():
    def __init__(self, Y_peak, contrast = 1000, gamma= 2.2, E_ambient= 0, k_refl = 0.005):
        #        Gain-gamma-offset display model to simulate SDR displays
        
        # dm = fvvdp_display_photo_gog( Y_peak )
        # dm = fvvdp_display_photo_gog( Y_peak, contrast )
        # dm = fvvdp_display_photo_gog( Y_peak, contrast, gamma )
        # dm = fvvdp_display_photo_gog( Y_peak, contrast, gamma, E_ambient )
        # dm = fvvdp_display_photo_gog( Y_peak, contrast, gamma, E_ambient, k_refl )
        
        # Parameters (default value shown in []):
        # Y_peak - display peak luminance in cd/m^2 (nit), e.g. 200 for a typical
        #          office monitor
        # contrast - [1000] the contrast of the display. The value 1000 means
        #          1000:1
        # gamma - [2.2] gamma of the display.
        # E_ambient - [0] ambient light illuminance in lux, e.g. 600 for bright
        #         office
        # k_refl - [0.005] reflectivity of the display screen
        
        # For more details on the GOG display model, see:
        # https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2016perceptual_display.pdf
        
        # Copyright (c) 2010-2021, Rafal Mantiuk 
        self.Y_peak = Y_peak
        self.contrast = contrast
        self.gamma = gamma
        self.E_ambient = E_ambient
        self.k_refl = k_refl
    
    def get_black_level(self):
        Y_refl = self.E_ambient/pi*self.k_refl # Reflected ambient light            
        Y_black = Y_refl + self.Y_peak/self.contrast
        return Y_black
    
    def forward(self,V):
        # Transforms gamma-correctec pixel values V, which must be in the range
        # 0-1, into absolute linear colorimetric values emitted from
        # the display.
        if torch.any(V>1) or torch.any(V<0) :
            print( Warning('Pixel values must be in the range 0-1'))
        Y_black = self.get_black_level()
        L = (self.Y_peak-Y_black)*(V**self.gamma) + Y_black
        return L
    
    def print(self):
        Y_black = self.get_black_level()
        print( 'Photometric display model:' )
        print( '  Peak luminance: {} cd/m^2'.format(self.Y_peak) )
        print( '  Contrast - theoretical: {}:1'.format(round(self.contrast) ))
        print( '  Contrast - effective: {}:1'.format(round(self.Y_peak/Y_black) ))
        print( '  Ambient light: {} lux'.format(self.E_ambient ))
        print( '  Display reflectivity: {}'.format(self.k_refl*100 ))