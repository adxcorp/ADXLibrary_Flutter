#import "AdxSdkNativeAdView.h"
#import "AdxFlutterNativeAdView.h"
#import <ADXLibrary/ADXNativeAdFactory.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AppLovinSDK/AppLovinSDK.h>

@interface AdxSdkNativeAdView() <ADXNativeAdFactoryDelegate>
@property FlutterMethodChannel * channel;
@property (copy) NSString * adUnitId;
@property (nullable) ADXNativeAd * nativeAd;
@property UIView * platformView;
@property UIView <ADXNativeAdRendering> * nativeAdView;
@property (assign) NSInteger mainImageLoadCount;
@end

@implementation AdxSdkNativeAdView

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                     adUnitId:(NSString *)adUnitId
                    messenger:(id<FlutterBinaryMessenger>)messenger {
    self = [super init];
    if (self) {
        self.adUnitId = adUnitId;
        NSString *uniqueChannelName = [NSString stringWithFormat:@"adx_sdk/native_ad_view_%lld", viewId];
        self.channel = [FlutterMethodChannel methodChannelWithName:uniqueChannelName binaryMessenger:messenger];
        
        __weak typeof(self) weakSelf = self;
        [self.channel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
            [weakSelf handleMethodCall:call result:result];
        }];
        
        self.platformView = [[UIView alloc] initWithFrame:frame];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"loadNativeAd" isEqualToString:call.method]) {
        [self loadNativeAd];
        result(nil);
    } else if ([@"destroyNativeAd" isEqualToString:call.method]) {
        [self destroyNativeAd];
        result(nil);
    } else {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@:", call.method]);
        if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector withObject:call];
#pragma clang diagnostic pop
            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    }
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)destroyNativeAd {
    [[ADXNativeAdFactory sharedInstance] removeDelegate:self];
    
    self.nativeAd = nil;
    if (self.nativeAdView) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
        [self.nativeAdView removeFromSuperview];
        self.nativeAdView = nil;
    }
    self.mainImageLoadCount = 0;
}

- (void)loadNativeAd {
    [self destroyNativeAd];
    
    [[ADXNativeAdFactory sharedInstance] addDelegate:self];
    [[ADXNativeAdFactory sharedInstance] setRenderingViewClass:self.adUnitId
                                            renderingViewClass:[AdxFlutterNativeAdView class]];
    
    [[ADXNativeAdFactory sharedInstance] loadAd:self.adUnitId];
}

#pragma mark - ADXNativeAdFactoryDelegate

- (void)onSuccess:(NSString *)adUnitId nativeAd:(ADXNativeAd *)nativeAd {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (![self.adUnitId isEqualToString:adUnitId]) return;
    
    self.nativeAd = nativeAd;
    
    UIView *factoryView = [[ADXNativeAdFactory sharedInstance] getNativeAdView:adUnitId];
    UIView *targetAdView = [self findTargetAdView:factoryView];
    
    self.nativeAdView = (UIView<ADXNativeAdRendering> *)targetAdView;
    
    if (!self.nativeAd || !self.nativeAdView) {
        NSLog(@"nativeAd or nativeAdView is nil");
        [self onFailure:adUnitId];
        return;
    }
    
    [self setupLayoutForFactoryView:factoryView targetAdView:targetAdView];
    [self hideUnusedAssetViews];

    NSMutableDictionary *arguments = [[self extractAdDataFromNativeAd:targetAdView] mutableCopy];
    arguments[@"ad_unit_id"] = adUnitId;
    
    [AdxSdkPlugin sendEventWithName:@"NativeAd_onSuccess" arguments:arguments channel:self.channel];
}

- (void)onFailure:(NSString *)adUnitId {
    [AdxSdkPlugin sendEventWithName:@"NativeAd_onFailure" arguments:@{@"ad_unit_id": adUnitId} channel:self.channel];
}

- (nonnull UIView *)view {
    return self.platformView;
}

#pragma mark - Helper Methods

- (UIView *)fetchViewWithAdMobSel:(SEL)adMobSel appLovinSel:(SEL)appLovinSel adxSel:(SEL)adxSel {
    UIView *view = nil;
    if ([self.nativeAdView isKindOfClass:[GADNativeAdView class]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self.nativeAdView respondsToSelector:adMobSel]) {
            view = [self.nativeAdView performSelector:adMobSel];
        }
    } else if ([self.nativeAdView isKindOfClass:[MANativeAdView class]]) {
        if ([self.nativeAdView respondsToSelector:appLovinSel]) {
            view = [self.nativeAdView performSelector:appLovinSel];
        }
    } else if ([self.nativeAdView respondsToSelector:adxSel]) {
        view = [self.nativeAdView performSelector:adxSel];
    }
#pragma clang diagnostic pop
    return view;
}

- (void)configureView:(UIView *)view frame:(CGRect)frame transparent:(BOOL)transparent {
    if (!view) return;

    if (view.superview != self.nativeAdView) {
        [view removeFromSuperview];
        [self.nativeAdView addSubview:view];
    }
    
    view.translatesAutoresizingMaskIntoConstraints = YES;
    if (view.constraints.count > 0) {
        [view removeConstraints:view.constraints];
    }
    
    view.frame = frame;
    view.hidden = NO;
    
    if (transparent) {
        view.backgroundColor = [UIColor clearColor];
        if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).textColor = [UIColor clearColor];
        } else if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            [btn setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor clearColor] forState:UIControlStateHighlighted];
            [btn setTitleColor:[UIColor clearColor] forState:UIControlStateSelected];
        }
    }
}

- (CGRect)frameForCall:(FlutterMethodCall *)call {
    NSDictionary *args = call.arguments;
    return CGRectMake([args[@"x"] floatValue], [args[@"y"] floatValue], [args[@"width"] floatValue], [args[@"height"] floatValue]);
}

#pragma mark - Asset Binding Methods

- (void)addTitleTextView:(FlutterMethodCall *)call {
    UIView *view = [self fetchViewWithAdMobSel:@selector(headlineView)
                                  appLovinSel:@selector(titleLabel)
                                       adxSel:@selector(nativeTitleTextLabel)];
    [self configureView:view frame:[self frameForCall:call] transparent:YES];
}

- (void)addMainImageView:(FlutterMethodCall *)call {
    UIView *view = [self fetchViewWithAdMobSel:@selector(mediaView)
                                  appLovinSel:@selector(mediaContentView)
                                       adxSel:@selector(nativeMainImageView)];
    
    [self configureView:view frame:[self frameForCall:call] transparent:NO];
    
    if (!view) return;

    // Flicker Mitigation
    self.mainImageLoadCount++;
    if (self.mainImageLoadCount == 1) {
        view.hidden = YES;
        __weak UIView *weakView = view;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakView) weakView.hidden = NO;
        });
    }
}

- (void)addMainTextView:(FlutterMethodCall *)call {
    UIView *view = [self fetchViewWithAdMobSel:@selector(bodyView)
                                  appLovinSel:@selector(bodyLabel)
                                       adxSel:@selector(nativeMainTextLabel)];
    [self configureView:view frame:[self frameForCall:call] transparent:YES];
}

- (void)addIconImageView:(FlutterMethodCall *)call {
    UIView *view = [self fetchViewWithAdMobSel:@selector(iconView)
                                  appLovinSel:@selector(iconImageView)
                                       adxSel:@selector(nativeIconImageView)];
    [self configureView:view frame:[self frameForCall:call] transparent:NO];
}

- (void)addCTAButtonView:(FlutterMethodCall *)call {
    UIView *view = [self fetchViewWithAdMobSel:@selector(callToActionView)
                                  appLovinSel:@selector(callToActionButton)
                                       adxSel:@selector(nativeCallToActionButton)];
    
    [self configureView:view frame:[self frameForCall:call] transparent:YES];
    
    if (view) {
        view.userInteractionEnabled = YES;
        [self.nativeAdView bringSubviewToFront:view];
        
        // AdMob Re-binding Workaround
        if ([self.nativeAdView isKindOfClass:[GADNativeAdView class]]) {
            GADNativeAdView *gadView = (GADNativeAdView *)self.nativeAdView;
            gadView.callToActionView = view;
            id currentAd = gadView.nativeAd;
            if (currentAd) {
                gadView.nativeAd = nil;
                gadView.nativeAd = currentAd;
            }
        }
    }
}

- (void)addPrivacyIconImageView:(FlutterMethodCall *)call {
    UIView *view = [self fetchViewWithAdMobSel:@selector(adChoicesView)
                                  appLovinSel:@selector(optionsContentView)
                                       adxSel:@selector(nativePrivacyInformationIconImageView)];
    [self configureView:view frame:[self frameForCall:call] transparent:NO];
}

#pragma mark - Layout & Helpers

- (UIView *)findTargetAdView:(UIView *)factoryView {
    if ([factoryView isKindOfClass:[GADNativeAdView class]] ||
        [factoryView isKindOfClass:[MANativeAdView class]] ||
        [factoryView conformsToProtocol:@protocol(ADXNativeAdRendering)]) {
        return factoryView;
    }
    
    UIView *firstSubview = [factoryView.subviews firstObject];
    if (firstSubview && ([firstSubview isKindOfClass:[GADNativeAdView class]] ||
                         [firstSubview isKindOfClass:[MANativeAdView class]] ||
                         [firstSubview conformsToProtocol:@protocol(ADXNativeAdRendering)])) {
        return firstSubview;
    }
    
    return factoryView;
}

- (void)setupLayoutForFactoryView:(UIView *)factoryView targetAdView:(UIView *)targetAdView {
    [self.platformView addSubview:factoryView];
    factoryView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [factoryView.topAnchor constraintEqualToAnchor:self.platformView.topAnchor],
        [factoryView.bottomAnchor constraintEqualToAnchor:self.platformView.bottomAnchor],
        [factoryView.leadingAnchor constraintEqualToAnchor:self.platformView.leadingAnchor],
        [factoryView.trailingAnchor constraintEqualToAnchor:self.platformView.trailingAnchor]
    ]];
    
    if (targetAdView != factoryView && [targetAdView superview] == factoryView) {
        targetAdView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [targetAdView.topAnchor constraintEqualToAnchor:factoryView.topAnchor],
            [targetAdView.bottomAnchor constraintEqualToAnchor:factoryView.bottomAnchor],
            [targetAdView.leadingAnchor constraintEqualToAnchor:factoryView.leadingAnchor],
            [targetAdView.trailingAnchor constraintEqualToAnchor:factoryView.trailingAnchor]
        ]];
    }
    [self.platformView layoutIfNeeded];
}

- (void)hideUnusedAssetViews {
    NSArray *selectors = @[
        @"headlineView", @"bodyView", @"iconView", @"imageView", @"mediaView",
        @"callToActionView", @"advertiserView", @"storeView", @"priceView", @"starRatingView", @"adChoicesView",
        @"titleLabel", @"advertiserLabel", @"bodyLabel", @"callToActionButton", @"iconImageView",
        @"mediaContentView", @"starRatingContentView", @"optionsContentView"
    ];
    
    for (NSString *selName in selectors) {
        SEL sel = NSSelectorFromString(selName);
        if ([self.nativeAdView respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            UIView *view = (UIView *)[self.nativeAdView performSelector:sel];
#pragma clang diagnostic pop
            if (!view) continue;
            
            if (view.superview != self.nativeAdView) {
                [view removeFromSuperview];
                [self.nativeAdView addSubview:view];
            }
            
            view.translatesAutoresizingMaskIntoConstraints = YES;
            if (view.constraints.count > 0) [view removeConstraints:view.constraints];
            
            BOOL isPrivacy = [selName isEqualToString:@"adChoicesView"] || [selName isEqualToString:@"optionsContentView"];
            if (isPrivacy) {
                view.frame = CGRectMake(self.nativeAdView.bounds.size.width - 17, 2, 15, 15);
                view.hidden = NO;
            } else {
                view.frame = CGRectMake([selectors indexOfObject:selName], 0, 1, 1);
                view.hidden = YES;
            }
        }
    }
}

- (NSDictionary *)extractAdDataFromNativeAd:(UIView *)nativeAdView {
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    
    // Helper block to safely extract text
    void (^extract)(NSString *key, id view, BOOL isButton) = ^(NSString *key, id view, BOOL isButton) {
        if (!args[key] && view) {
            if (isButton && [view isKindOfClass:[UIButton class]]) {
                NSString *t = [view currentTitle];
                if (t) args[key] = t;
            } else if ([view isKindOfClass:[UILabel class]]) {
                NSString *t = [view text];
                if (t) args[key] = t;
            }
        }
    };
    
    if ([nativeAdView isKindOfClass:[GADNativeAdView class]]) {
        GADNativeAdView *v = (GADNativeAdView *)nativeAdView;
        extract(@"headline", v.headlineView, NO);
        extract(@"body", v.bodyView, NO);
        extract(@"callToAction", v.callToActionView, [v.callToActionView isKindOfClass:[UIButton class]]);
    } else if ([nativeAdView isKindOfClass:[MANativeAdView class]]) {
        MANativeAdView *v = (MANativeAdView *)nativeAdView;
        if (v.titleLabel.text) args[@"headline"] = v.titleLabel.text;
        if (v.bodyLabel.text) args[@"body"] = v.bodyLabel.text;
        if (v.callToActionButton.currentTitle) args[@"callToAction"] = v.callToActionButton.currentTitle;
    } else if ([nativeAdView conformsToProtocol:@protocol(ADXNativeAdRendering)]) {
        UIView<ADXNativeAdRendering> *v = (UIView<ADXNativeAdRendering> *)nativeAdView;
        if ([v respondsToSelector:@selector(nativeTitleTextLabel)]) extract(@"headline", v.nativeTitleTextLabel, NO);
        if ([v respondsToSelector:@selector(nativeMainTextLabel)]) extract(@"body", v.nativeMainTextLabel, NO);
        if ([v respondsToSelector:@selector(nativeCallToActionButton)]) extract(@"callToAction", v.nativeCallToActionButton, YES);
    }
    return args;
}

@end
