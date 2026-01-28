#import "AdxSdkPlugin.h"
#import "AdxSdkNativeAdViewFactory.h"
#import "AdxSdkNativeAdView.h"

@interface AdxSdkNativeAdViewFactory()
@property (nonatomic, strong) id<FlutterBinaryMessenger> messenger;
@end

@implementation AdxSdkNativeAdViewFactory

- (instancetype)initWithMessenger:(id<FlutterBinaryMessenger>)messenger {
    self = [super init];
    if ( self ) {
        self.messenger = messenger;
    }
    return self;
}

- (id<FlutterMessageCodec>)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (id<FlutterPlatformView>)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    ADXSdk * sdk = [AdxSdkPlugin shared];
    if(![sdk isInitialized]) {
        NSLog(@"ADX Flutter Plugin must be initialized.");
        return nil;
    }
    
    NSString * adUnitId = args[@"ad_unit_id"];
    if(![adUnitId length]) {
        NSLog(@"AdUnitID cannot be empty.");
        return nil;
    }
    
    return [[AdxSdkNativeAdView alloc] initWithFrame:frame
                                              viewId:viewId
                                            adUnitId:adUnitId
                                           messenger:self.messenger];
}

@end

