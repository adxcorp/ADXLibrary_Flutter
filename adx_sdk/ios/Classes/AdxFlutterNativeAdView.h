#import <UIKit/UIKit.h>
#import <ADXLibrary/ADXNativeAdFactory.h>
#import <ADXLibrary/ADXNativeAdRendering.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdxFlutterNativeAdView : UIView <ADXNativeAdRendering>
@property UILabel * nativeTitleTextLabel;
@property UILabel * nativeMainTextLabel;
@property UIButton * nativeCallToActionButton;
@property UIImageView * nativeIconImageView;
@property UIImageView * nativeMainImageView;
@property UIImageView * nativePrivacyInformationIconImageView;

- (instancetype)init;
@end

NS_ASSUME_NONNULL_END
