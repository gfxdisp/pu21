import torch
from pu21_encoder import pu21_encoder
from ignite.metrics import SSIM,PSNR
from skimage.metrics import structural_similarity

def pu21_metric( I_test, I_reference, metric, display_model=None ):
    """
    A convenience function for calling traditional (SDR) metrics on
    PU-encoded pixel values. This is useful for adapting traditional metrics
    to HDR images.

    Q = pu21_metric( I_test, I_reference, metric ) % for HDR images
    Q = pu21_metric( I_test, I_reference, metric, display_model ) % for SDR

    When no display model is passed, I_test and I_reference must be provided
    as ABSOLUTE linear colour or luminance values. If unsure what those values
    are, please refer to the paper [1].

    When display model is passed, I_test and I_reference contain images in
    display-encoded sRGB colour space or luma (standard images). If images
    are stored as floating point values, the values must be in the range 0-1.
    If they are stored as integers, they must be in the range
    from 0 to maxint(class(I)).

    display_model is an object of the class pu21_display_model_gog. Check
    exaples/ex_sdr_images.m on how to create an object of this class.

    metric can be either 'PSNR', 'SSIM'. You can also pass a handle to a
    function Q = fun(I_test, I_referece). The function should expect both
    images to be stored as floating point numbers and the typical range from
    0 to 255. The range of values can be higher for bright HDR images or
    bright SDR displays.

    [1] 1. Mantiuk RK.
    Practicalities of predicting quality of high dynamic range images and video.
    In: 2016 IEEE International Conference on Image Processing (ICIP), p. 904–8.
    https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2016prac_hdr_metrics.pdf
    http://dx.doi.org/10.1109/ICIP.2016.7532488


    If images are stored as intigers, convert to a single precision floating
    point between 0 and 1.
    """
    I_test = torch.tensor(I_test)
    if not I_test.is_floating_point():
        print( Warning("Hardcoded 255, this is super cursed to do in python"))
        I_test = I_test.to(torch.float)/255
    if not I_reference.is_floating_point():
        print( Warning("Hardcoded 255, this is super cursed to do in python"))
        I_reference = I_reference.to(torch.float)/255 
    
    if display_model !=None:
        L_test = display_model.forward( I_test )
        L_reference = display_model.forward( I_reference )
    else:
        L_test = I_test
        L_reference = I_reference
    
    pu21 = pu21_encoder()
    P_test = pu21.encode( L_test )
    P_reference = pu21.encode( L_reference )
    P_test = P_test.permute(2,1,0)
    P_reference = P_reference.permute(2,1,0)
    print("P_test max", torch.max( P_test)) 
    if isinstance(metric, str):
        metricFunc = None
        if metric.lower() == 'psnr':
            metricFunc = PSNR(255)
        if metric.lower() == 'ssim':
            # Note that we are passing floating point values, which are in the
            # range 0-256 for the luminance range 0.1 to 100 cd/m^2
            #metricFunc = SSIM(255,kernel_size=(101,101))
            P_test = P_test.permute(1,2,0)
            P_reference = P_reference.permute(1,2,0)
            return structural_similarity(P_test.numpy(),P_reference.numpy(),multichannel=True,data_range=255)
        if metricFunc==None:
            raise Exception( 'Unknown metric {}'.format(metric) )
        else:
            metricFunc.update((P_test.unsqueeze(0),P_reference.unsqueeze(0)))
            Q = metricFunc.compute()
    else:
        Q = metric(P_test,P_reference)
    return Q
    
