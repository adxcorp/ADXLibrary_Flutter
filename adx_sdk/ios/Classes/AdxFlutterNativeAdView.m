#import "AdxFlutterNativeAdView.h"

@implementation AdxFlutterNativeAdView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.nativeTitleTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.nativeMainTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.nativeCallToActionButton = [[UIButton alloc] initWithFrame:CGRectZero];
    self.nativeIconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.nativeMainImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.nativePrivacyInformationIconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
}

@end
