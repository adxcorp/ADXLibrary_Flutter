
#import "AdxSdkPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdxSdkNativeAdView : NSObject<FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                    messenger:(id<FlutterBinaryMessenger>)messenger;

@end

NS_ASSUME_NONNULL_END
