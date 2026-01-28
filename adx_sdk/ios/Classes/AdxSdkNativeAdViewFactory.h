
#import "AdxSdkPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdxSdkNativeAdViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger;

@end

NS_ASSUME_NONNULL_END
