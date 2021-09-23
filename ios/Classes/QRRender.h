//
//  YDQRRender.h
//  flutter_qrcode
//
//  Created by sue on 2021/9/23.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
NS_ASSUME_NONNULL_BEGIN
typedef void(^PreviewUpdateCallback)(void);
typedef void(^ResultCallback)(NSString *);

@interface QRRender : NSObject<FlutterTexture>

- (instancetype)initWithFrameUpdateCallback:(PreviewUpdateCallback)callback result:(ResultCallback)result;

- (void)startRender;

- (void)stopRender;

- (void)openFlashlight;

- (void)closeFlashlight;


+ (NSData *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(NSData *)logoData;
@end

NS_ASSUME_NONNULL_END
