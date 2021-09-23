//
//  YDQRCodeObtain.m
//  flutter_qrcode
//
//  Created by sue on 2021/9/23.
//

#import "QRCodeObtain.h"


@implementation YDQRCodeObtainConfigure

+ (instancetype)QRCodeObtainConfigure {
    return [[self alloc] init];
}

- (NSString *)sessionPreset {
    if (!_sessionPreset) {
        _sessionPreset = AVCaptureSessionPreset1920x1080;
    }
    return _sessionPreset;
}

- (NSArray *)metadataObjectTypes {
    if (!_metadataObjectTypes) {
        _metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    return _metadataObjectTypes;
}

@end


@interface QRCodeObtain () <AVCaptureMetadataOutputObjectsDelegate,
                        AVCaptureVideoDataOutputSampleBufferDelegate,
                        AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) YDQRCodeObtainConfigure *configure;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, copy) YDQRCodeObtainScanResultBlock scanResultBlock;
@property (nonatomic, copy) YDQRCodeObtainScanBrightnessBlock scanBrightnessBlock;
@property (nonatomic, copy) YDQRCodeObtainBufferBlock bufferBlock;
@property (nonatomic, copy) NSString *detectorString;

@end
@implementation QRCodeObtain

+ (instancetype)QRCodeObtain {
    return [[self alloc] init];
}

- (void)dealloc {
    NSLog(@"YDQRCodeObtain - - dealloc");
}

#pragma mark - - 生成二维码相关方法
/**
 *  生成二维码
 *
 *  @param data    二维码数据
 *  @param size    二维码大小
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size {
    return [self generateQRCodeWithData:data size:size color:[UIColor blackColor] backgroundColor:[UIColor whiteColor]];
}
/**
 *  生成二维码
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param color    二维码颜色
 *  @param backgroundColor    二维码背景颜色
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor {
    NSData *string_data = [data dataUsingEncoding:NSUTF8StringEncoding];
    // 1、二维码滤镜
    CIFilter *fileter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [fileter setValue:string_data forKey:@"inputMessage"];
    [fileter setValue:@"H" forKey:@"inputCorrectionLevel"];
    CIImage *ciImage = fileter.outputImage;
    // 2、颜色滤镜
    CIFilter *color_filter = [CIFilter filterWithName:@"CIFalseColor"];
    [color_filter setValue:ciImage forKey:@"inputImage"];
    [color_filter setValue:[CIColor colorWithCGColor:color.CGColor] forKey:@"inputColor0"];
    [color_filter setValue:[CIColor colorWithCGColor:backgroundColor.CGColor] forKey:@"inputColor1"];
    // 3、生成处理
    CIImage *outImage = color_filter.outputImage;
    CGFloat scale = size / outImage.extent.size.width;
    outImage = [outImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    return [UIImage imageWithCIImage:outImage];
}
/**
 *  生成带 logo 的二维码（推荐使用）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param logoImage    logo
 *  @param ratio        logo 相对二维码的比例
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio {
    return [self generateQRCodeWithData:data size:size logoImage:logoImage ratio:ratio logoImageCornerRadius:5 logoImageBorderWidth:5 logoImageBorderColor:[UIColor whiteColor]];
}
/**
 *  生成带 logo 的二维码（拓展）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param logoImage    logo
 *  @param ratio        logo 相对二维码的比例
 *  @param logoImageCornerRadius    logo 外边框圆角
 *  @param logoImageBorderWidth     logo 外边框宽度
 *  @param logoImageBorderColor     logo 外边框颜色
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio logoImageCornerRadius:(CGFloat)logoImageCornerRadius logoImageBorderWidth:(CGFloat)logoImageBorderWidth logoImageBorderColor:(UIColor *)logoImageBorderColor {
    UIImage *image = [self generateQRCodeWithData:data size:size color:[UIColor blackColor] backgroundColor:[UIColor whiteColor]];
    if (logoImage == nil) return image;
    if (ratio < 0.0 || ratio > 0.5) {
        ratio = 0.25;
    }
    CGFloat logoImageW = ratio * size;
    CGFloat logoImageH = logoImageW;
    CGFloat logoImageX = 0.5 * (image.size.width - logoImageW);
    CGFloat logoImageY = 0.5 * (image.size.height - logoImageH);
    CGRect logoImageRect = CGRectMake(logoImageX, logoImageY, logoImageW, logoImageH);
    // 绘制logo
    UIGraphicsBeginImageContextWithOptions(image.size, false, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    if (logoImageCornerRadius < 0.0 || logoImageCornerRadius > 10) {
        logoImageCornerRadius = 5;
    }
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:logoImageRect cornerRadius:logoImageCornerRadius];
    if (logoImageBorderWidth < 0.0 || logoImageBorderWidth > 10) {
        logoImageBorderWidth = 5;
    }
    path.lineWidth = logoImageBorderWidth;
    [logoImageBorderColor setStroke];
    [path stroke];
    [path addClip];
    [logoImage drawInRect:logoImageRect];
    UIImage *QRCodeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return QRCodeImage;
}

#pragma mark - - 扫描二维码相关方法
- (void)establishQRCodeObtainScanWithConfigure:(YDQRCodeObtainConfigure *)configure {

    if (configure == nil) {
        @throw [NSException exceptionWithName:@"YDQRCode" reason:@"configure 参数不能为空" userInfo:nil];
    }
    
    _configure = configure;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    // 1、捕获设备输入流
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];

    // 2、捕获元数据输出流
    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
  
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 设置扫描范围（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）
    // 注：微信二维码的扫描范围是整个屏幕，这里并没有做处理（可不用设置）
    if (configure.rectOfInterest.origin.x == 0 && configure.rectOfInterest.origin.y == 0 && configure.rectOfInterest.size.width == 0 && configure.rectOfInterest.size.height == 0) {
    } else {
        metadataOutput.rectOfInterest = configure.rectOfInterest;
    }
    

    // 3、设置会话采集率
    self.captureSession.sessionPreset = configure.sessionPreset;
    
    // 4(1)、添加捕获元数据输出流到会话对象
    [_captureSession addOutput:metadataOutput];
    // 4(2)、添加捕获输出流到会话对象
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings =
        @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    AVCaptureConnection *connection =
        [AVCaptureConnection connectionWithInputPorts:deviceInput.ports
                                               output:videoDataOutput];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutput:videoDataOutput];
    // 4(3)、添加捕获设备输入流到会话对象
    [_captureSession addInput:deviceInput];
    
    // 5、设置数据输出类型，需要将数据输出添加到会话后，才能指定元数据类型，否则会报错
    metadataOutput.metadataObjectTypes = configure.metadataObjectTypes;

}



- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

- (void)startRunningWithBefore:(void (^)(void))before completion:(void (^)(void))completion {
    if (before) {
        before();
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.captureSession startRunning];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    });
}
- (void)stopRunning {
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - - AVCaptureMetadataOutputObjectsDelegate 的方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *resultString = nil;
    if (metadataObjects != nil && metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
        resultString = [obj stringValue];
        if (self.scanResultBlock) {
            self.scanResultBlock(self, resultString);
        }
    }
}
#pragma mark - - AVCaptureVideoDataOutputSampleBufferDelegate 的方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    CGFloat brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    if (_scanBrightnessBlock) {
        _scanBrightnessBlock(self,brightnessValue);
    }
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if (_bufferBlock) {
        _bufferBlock(self,sampleBuffer);
    }
}

- (void)setBlockWithQRCodeObtainScanResult:(YDQRCodeObtainScanResultBlock)block {
    _scanResultBlock = block;
}
- (void)setBlockWithQRCodeObtainScanBrightness:(YDQRCodeObtainScanBrightnessBlock)block {
    _scanBrightnessBlock = block;
}

- (void)setBlockWithQRCodeObtainBuffer:(YDQRCodeObtainBufferBlock)block {
    _bufferBlock = block;
}

#pragma mark - - 手电筒相关方法
- (void)openFlashlight {
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    if ([captureDevice hasTorch]) {
        BOOL locked = [captureDevice lockForConfiguration:&error];
        if (locked) {
            [captureDevice setTorchMode:AVCaptureTorchModeOn];
            [captureDevice unlockForConfiguration];
        }
    }
}
- (void)closeFlashlight {
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([captureDevice hasTorch]) {
        [captureDevice lockForConfiguration:nil];
        [captureDevice setTorchMode:AVCaptureTorchModeOff];
        [captureDevice unlockForConfiguration];
    }
}

@end
