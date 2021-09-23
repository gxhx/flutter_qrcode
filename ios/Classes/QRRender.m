//
//  YDQRRender.m
//  flutter_qrcode
//
//  Created by sue on 2021/9/23.
//

#import "QRRender.h"
#import "QRCodeObtain.h"
#import <libkern/OSAtomic.h>
@implementation QRRender {
    PreviewUpdateCallback _callback;
    ResultCallback _result;
    CVPixelBufferRef _target;
    QRCodeObtain *_obtain;
}

- (CVPixelBufferRef)copyPixelBuffer {

    CVBufferRetain(_target);
    return _target;
}

- (instancetype)initWithFrameUpdateCallback:(PreviewUpdateCallback)callback  result:(ResultCallback)result
{
    if (self = [super init]) {
        _callback = callback;
        _result = result;
        [self initObtain];
  
    }
    return self;
}

- (void)initObtain {
    _obtain = [QRCodeObtain QRCodeObtain];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    YDQRCodeObtainConfigure *configure = [YDQRCodeObtainConfigure QRCodeObtainConfigure];
    configure.sessionPreset = [self getSessionPresetForDevice:device];
    configure.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    // 这里只是提供了几种作为参考（共：13）；需什么类型添加什么类型即可
    NSArray *arr = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    configure.metadataObjectTypes = arr;
    [_obtain establishQRCodeObtainScanWithConfigure:configure];
  
    __weak typeof(self) wself = self;
    [_obtain setBlockWithQRCodeObtainBuffer:^(QRCodeObtain *obtain, CMSampleBufferRef buffer) {
        __strong typeof(self) strongSelf = wself;
        if (buffer && UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [strongSelf createCVBufferWith:buffer];
        }
    }];
   
    [_obtain setBlockWithQRCodeObtainScanResult:^(QRCodeObtain *obtain, NSString *result) {
        __strong typeof(self) strongSelf = wself;
        if (result && strongSelf->_result) {
            strongSelf->_result(result);
            [strongSelf stopRender];
        }
    }];


}

- (void)createCVBufferWith:(CMSampleBufferRef)source {
    
    CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(source);
    CFRetain(newBuffer);
    CVPixelBufferRef old = _target;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_target)) {
      old = _target;
    }
    if (old != nil) {
      CFRelease(old);
    }
    if ( _callback) {
        _callback();
    }
}

- (void)startRender
{
    [_obtain startRunningWithBefore:^{} completion:^{}];
}

- (void)stopRender {
    [_obtain stopRunning];
}

+ (NSData *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(NSData *)logoData {
    UIImage *image;
    if (logoData && [logoData isKindOfClass:NSData.class]) {
        UIImage *logoImage = [[UIImage alloc] initWithData:logoData];
        image  = [QRCodeObtain generateQRCodeWithData:data size:size logoImage:logoImage ratio:0.25];
    }else {
        image =  [QRCodeObtain generateQRCodeWithData:data size:size];
    }
    return UIImagePNGRepresentation(image);
}

- (NSString *)getSessionPresetForDevice:(AVCaptureDevice *)device {
    
    if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset3840x2160]) {
        return AVCaptureSessionPreset3840x2160;
    }else if([device supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh]){
        return AVCaptureSessionPresetHigh;
    }else if([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080]){
        return AVCaptureSessionPreset1920x1080;
    } else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]){
        return AVCaptureSessionPreset1280x720;
    } else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]){
        return AVCaptureSessionPreset640x480;
    } else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPresetMedium]){
        return AVCaptureSessionPresetMedium;
    } else if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset352x288]){
        return AVCaptureSessionPreset352x288;
    } else{
        return AVCaptureSessionPresetLow;
    }
}

- (void)openFlashlight{
    [_obtain openFlashlight];
}

- (void)closeFlashlight {
    [_obtain closeFlashlight];
}
@end
