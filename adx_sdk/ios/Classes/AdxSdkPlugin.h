#import <Flutter/Flutter.h>
#import <ADXLibrary/ADXLibrary.h>

@interface AdxSdkPlugin : NSObject<FlutterPlugin>
+ (ADXSdk *)shared;
+ (void)sendEventWithName:(NSString *)name
                arguments:(NSDictionary<NSString *, id> *)arguments
                  channel:(FlutterMethodChannel *)channel;
@end
