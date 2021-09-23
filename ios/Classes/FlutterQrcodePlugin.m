#import "FlutterQrcodePlugin.h"
#import "QRRender.h"
@interface FlutterQrcodePlugin ()
@property (nonatomic, strong) NSObject<FlutterTextureRegistry> *textures;
@property (nonatomic, strong) QRRender *render;
@property (nonatomic, strong)  FlutterMethodChannel *methodChannel;
@end

@implementation FlutterQrcodePlugin

- (instancetype) initWithTextures:(NSObject<FlutterTextureRegistry> *)textures {
    if (self = [super init]) {
        _textures = textures;
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"MethodChannel.qrcode" binaryMessenger:[registrar messenger]];
    
    FlutterQrcodePlugin *instance = [[FlutterQrcodePlugin alloc] initWithTextures:registrar.textures];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    instance.methodChannel = channel;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"init"]) {
        
        __block int64_t textureId = 0;
        
        __weak typeof(self) wself = self;
        _render = [[QRRender alloc] initWithFrameUpdateCallback:^{
            [wself.textures textureFrameAvailable:textureId];
        } result:^(NSString *result) {
            [wself.methodChannel
             invokeMethod:@"result"
             arguments:result];
        }];
        textureId = [_textures registerTexture:_render];
        [_render startRender];
        result(@(textureId));
    }else if ([call.method isEqualToString:@"resumeScan"]) {
        [_render startRender];
        result(@(YES));
    }else if ([call.method isEqualToString:@"pauseScan"]) {
        [_render stopRender];
        result(@(YES));
    }else if ([call.method isEqualToString:@"dispose"]) {
        _render = nil;
        result(@(YES));
    }else if ([call.method isEqualToString:@"generateQRCode"]) {
        NSDictionary *dict = call.arguments;
        NSString *data = [dict valueForKey:@"data"];
        NSNumber *size = [dict valueForKey:@"size"];
        NSData *icon = [dict valueForKey:@"icon"];
        
        NSData *resultData =  [QRRender generateQRCodeWithData:data size:size.floatValue logoImage:icon];
        
        result(resultData);
    }else if ([call.method isEqualToString:@"openFlashlight"]) {
        [_render openFlashlight];
        result(@(YES));
    }else if ([call.method isEqualToString:@"closeFlashlight"]) {
        [_render closeFlashlight];
        result(@(YES));
    }else {
        result(FlutterMethodNotImplemented);
    }
}

@end
