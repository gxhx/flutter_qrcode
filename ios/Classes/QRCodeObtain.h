//
//  YDQRCodeObtain.h
//  flutter_qrcode
//
//  Created by sue on 2021/9/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@class QRCodeObtain;
typedef void(^YDQRCodeObtainScanResultBlock)(QRCodeObtain *obtain, NSString *result);
typedef void(^YDQRCodeObtainScanBrightnessBlock)(QRCodeObtain *obtain, CGFloat brightness);
typedef void(^YDQRCodeObtainBufferBlock)(QRCodeObtain *obtain, CMSampleBufferRef buffer);


@interface YDQRCodeObtainConfigure : NSObject
/** 类方法创建 */
+ (instancetype)QRCodeObtainConfigure;
/** 会话预置，默认为：AVCaptureSessionPreset1920x1080 */
@property (nonatomic, copy) NSString *sessionPreset;
/** 元对象类型，默认为：AVMetadataObjectTypeQRCode */
@property (nonatomic, strong) NSArray *metadataObjectTypes;
/** 扫描范围，默认整个视图（每一个取值 0 ～ 1，以屏幕右上角为坐标原点）*/
@property (nonatomic, assign) CGRect rectOfInterest;

@end



@interface QRCodeObtain : NSObject
/** 类方法创建 */
+ (instancetype)QRCodeObtain;

#pragma mark - - 生成二维码相关方法
/**
 *  生成二维码
 *
 *  @param data    二维码数据
 *  @param size    二维码大小
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size;
/**
 *  生成二维码（自定义颜色）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param color    二维码颜色
 *  @param backgroundColor    二维码背景颜色
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor;
/**
 *  生成带 logo 的二维码（推荐使用）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param logoImage    logo
 *  @param ratio        logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio;
/**
 *  生成带 logo 的二维码（拓展）
 *
 *  @param data     二维码数据
 *  @param size     二维码大小
 *  @param logoImage    logo
 *  @param ratio        logo 相对二维码的比例（取值范围 0.0 ～ 0.5f）
 *  @param logoImageCornerRadius    logo 外边框圆角（取值范围 0.0 ～ 10.0f）
 *  @param logoImageBorderWidth     logo 外边框宽度（取值范围 0.0 ～ 10.0f）
 *  @param logoImageBorderColor     logo 外边框颜色
 */
+ (UIImage *)generateQRCodeWithData:(NSString *)data size:(CGFloat)size logoImage:(UIImage *)logoImage ratio:(CGFloat)ratio logoImageCornerRadius:(CGFloat)logoImageCornerRadius logoImageBorderWidth:(CGFloat)logoImageBorderWidth logoImageBorderColor:(UIColor *)logoImageBorderColor;

#pragma mark - - 扫描二维码相关方法
/** 创建扫描二维码方法 */
- (void)establishQRCodeObtainScanWithConfigure:(YDQRCodeObtainConfigure *)configure;
/** 扫描二维码回调方法 */
- (void)setBlockWithQRCodeObtainScanResult:(YDQRCodeObtainScanResultBlock)block;
/** 扫描二维码光线强弱回调方法；调用之前配置属性 sampleBufferDelegate 必须为 YES */
- (void)setBlockWithQRCodeObtainScanBrightness:(YDQRCodeObtainScanBrightnessBlock)block;
/** 扫描二维码纹理数据；调用之前配置属性 sampleBufferDelegate 必须为 YES */
- (void)setBlockWithQRCodeObtainBuffer:(YDQRCodeObtainBufferBlock)block;
/** 开启扫描回调方法 */
- (void)startRunningWithBefore:(void (^)(void))before completion:(void (^)(void))completion;
/** 停止扫描方法 */
- (void)stopRunning;

#pragma mark - - 手电筒相关方法
/** 打开手电筒 */
- (void)openFlashlight;
/** 关闭手电筒 */
- (void)closeFlashlight;

@end

NS_ASSUME_NONNULL_END
