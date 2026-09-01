#import "AdxSdkPlugin.h"

@interface AdxSdkPlugin () <ADXAdViewDelegate, ADXInterstitialAdDelegate, ADXRewardedAdDelegate>
@property(strong) NSMutableDictionary<NSString *, ADXAdView *> *adViews;
@property(strong) NSMutableDictionary<NSString *, NSString *> *adViewPositions;
@property(strong) NSMutableDictionary<NSString *, NSArray<NSLayoutConstraint *> *> *adViewConstraints;
@property(strong) NSMutableDictionary<NSString *, ADXInterstitialAd *> *interstitials;
@property(strong) NSMutableDictionary<NSString *, ADXRewardedAd *> *rewardedAds;
@property(strong) UIView *safeAreaBackground;
@property(strong) FlutterMethodChannel *channel;
@property(strong) NSDictionary<NSString *, void (^)(FlutterMethodCall *, FlutterResult)> *methodHandlers;
@end

@implementation AdxSdkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    AdxSdkPlugin *instance = [[AdxSdkPlugin alloc] init];
    instance.channel =
            [FlutterMethodChannel methodChannelWithName:@"adx_sdk"
                                        binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:instance.channel];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _adViews = [NSMutableDictionary dictionary];
        _adViewPositions = [NSMutableDictionary dictionary];
        _adViewConstraints = [NSMutableDictionary dictionary];
        _interstitials = [NSMutableDictionary dictionary];
        _rewardedAds = [NSMutableDictionary dictionary];
        _safeAreaBackground = [[UIView alloc] init];
        _safeAreaBackground.hidden = YES;
        _safeAreaBackground.userInteractionEnabled = NO;
        _safeAreaBackground.translatesAutoresizingMaskIntoConstraints = NO;

        __weak typeof(self) weakSelf = self;
        _methodHandlers = @{
                @"initialize":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_initialize:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"isInitialized":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_isInitialized:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"setBannerPosition":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_setBannerPosition:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"loadBannerAd":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_loadBannerAd:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"destroyBannerAd":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_destroyBannerAd:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"loadInterstitial":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_loadInterstitial:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"isInterstitialLoaded": ^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_isInterstitialLoaded:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"showInterstitial":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_showInterstitial:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"destroyInterstitial":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_destroyInterstitial:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"loadRewardedAd":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_loadRewardedAd:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"isRewardedAdLoaded":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_isRewardedAdLoaded:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"showRewardedAd":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_showRewardedAd:c result:r] : r(FlutterMethodNotImplemented);
                },
                @"destroyRewardedAd":^(FlutterMethodCall *c, FlutterResult r) {
                    typeof(weakSelf) s = weakSelf; s ? [s handle_destroyRewardedAd:c result:r] : r(FlutterMethodNotImplemented);
                },
        };
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
    void (^handler)(FlutterMethodCall *, FlutterResult) =
    self.methodHandlers[call.method];
    if (handler) {
        handler(call, result);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Method Handlers

- (void)handle_initialize:(FlutterMethodCall *)call
                   result:(FlutterResult)result {
    NSString *appId = call.arguments[@"app_id"];
    NSArray *testDevices = call.arguments[@"test_devices"];
    ADXGdprType gdpr = [self getGdprType:call.arguments[@"gdpr_type"]];

    ADXConfiguration *config =
            [[ADXConfiguration alloc] initWithAppId:appId
                                           gdprType:gdpr
                                        testDevices:testDevices];
#ifdef DEBUG
    config.logLevel = ADXLogLevelDebug;
#else
    config.logLevel = ADXLogLevelNone;
#endif

    [[ADXSdk sharedInstance]
            initializeWithConfiguration:config
                      completionHandler:^(BOOL resultFlag,
                                          ADXConsentState consentState) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              result(@{
                                             @"result" : @(resultFlag),
                                             @"consent" : @(consentState)
                                     });
                          });
                      }];
}

- (void)handle_isInitialized:(FlutterMethodCall *)call
                      result:(FlutterResult)result {
    result(@([[ADXSdk sharedInstance] isInitialized]));
}

- (void)handle_setBannerPosition:(FlutterMethodCall *)call
                          result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    self.adViewPositions[adUnitId] = call.arguments[@"position"];
    [self updatePositionAdView:adUnitId];
    result(nil);
}

- (void)handle_loadBannerAd:(FlutterMethodCall *)call
                     result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    NSString *size = call.arguments[@"size"];
    if (CGSizeEqualToSize([self adViewSize:size], CGSizeZero)) {
        result([FlutterError
                       errorWithCode:@"invalid_size"
                             message:[NSString
                                     stringWithFormat:@"Unsupported banner size: %@", size]
                             details:nil]);
        return;
    }
    ADXAdView *adView = [self retrieveAdView:adUnitId size:size];
    if (!adView) {
        result([FlutterError errorWithCode:@"no_view_controller"
                                   message:@"No active view controller"
                                   details:nil]);
        return;
    }
    adView.delegate = self;
    [self updatePositionAdView:adUnitId];
    [adView loadAd];
    result(nil);
}

- (void)handle_destroyBannerAd:(FlutterMethodCall *)call
                        result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    ADXAdView *adView = self.adViews[adUnitId];
    if (adView) {
        adView.delegate = nil;
        [NSLayoutConstraint deactivateConstraints:self.adViewConstraints[adUnitId]];
        [adView removeFromSuperview];
        [self.adViews removeObjectForKey:adUnitId];
        [self.adViewPositions removeObjectForKey:adUnitId];
        [self.adViewConstraints removeObjectForKey:adUnitId];
        if (self.adViews.count == 0) {
            [self.safeAreaBackground removeFromSuperview];
            self.safeAreaBackground.hidden = YES;
        }
    }
    result(nil);
}

- (void)handle_loadInterstitial:(FlutterMethodCall *)call
                         result:(FlutterResult)result {
    ADXInterstitialAd *ad = [self retrieveInterstitial:call.arguments[@"ad_unit_id"]];
    ad.delegate = self;
    [ad loadAd];
    result(nil);
}

- (void)handle_isInterstitialLoaded:(FlutterMethodCall *)call
                             result:(FlutterResult)result {
    ADXInterstitialAd *ad = self.interstitials[call.arguments[@"ad_unit_id"]];
    result(ad != nil && ad.isLoaded ? @YES : @NO);
}

- (void)handle_showInterstitial:(FlutterMethodCall *)call
                         result:(FlutterResult)result {
    ADXInterstitialAd *ad = self.interstitials[call.arguments[@"ad_unit_id"]];
    if (ad.isLoaded) {
        UIViewController *rootVC = [self topViewController];
        if (rootVC) {
            [ad showAdFromRootViewController:rootVC];
        } else {
            NSError *error = [NSError errorWithDomain:@"AdxSdk" code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"No active view controller"}];
            [self interstitialAd:ad didFailToShowWithError:error];
        }
    }
    result(nil);
}

- (void)handle_destroyInterstitial:(FlutterMethodCall *)call
                            result:(FlutterResult)result {
    // interstitials에서 객체를 제거해도 얻는 메모리 이득이 미미하고,
    // 제거 후 재로드 시 객체 재생성 타이밍에 따른 사이드 이펙트가 발생할 수 있어
    // 호환성 유지 목적으로 메서드는 남기되 아무 작업도 하지 않음.
    result(nil);
}

- (void)handle_loadRewardedAd:(FlutterMethodCall *)call
                       result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    ADXRewardedAd *ad = [self retrieveRewardedAd:adUnitId];
    ad.delegate = self;
    NSString *userId = call.arguments[@"user_id"];
    NSString *customData = call.arguments[@"custom_data"];
    if (userId.length)
        [ad setSSVOptionWithUserId:userId];
    if (customData.length)
        [ad setSSVOptionWithCustomData:customData];
    [ad loadAd];
    result(nil);
}

- (void)handle_isRewardedAdLoaded:(FlutterMethodCall *)call
                           result:(FlutterResult)result {
    ADXRewardedAd *ad = self.rewardedAds[call.arguments[@"ad_unit_id"]];
    result(ad != nil && ad.isLoaded ? @YES : @NO);
}

- (void)handle_showRewardedAd:(FlutterMethodCall *)call
                       result:(FlutterResult)result {
    ADXRewardedAd *ad = self.rewardedAds[call.arguments[@"ad_unit_id"]];
    if (ad.isLoaded) {
        NSString *userId = call.arguments[@"user_id"];
        NSString *customData = call.arguments[@"custom_data"];
        if (userId.length)
            [ad setSSVOptionWithUserId:userId];
        if (customData.length)
            [ad setSSVOptionWithCustomData:customData];
        UIViewController *rootVC = [self topViewController];
        if (rootVC) {
            [ad showAdFromRootViewController:rootVC];
        } else {
            NSError *error = [NSError errorWithDomain:@"AdxSdk" code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"No active view controller"}];
            [self rewardedAd:ad didFailToShowWithError:error];
        }
    }
    result(nil);
}

- (void)handle_destroyRewardedAd:(FlutterMethodCall *)call
                          result:(FlutterResult)result {
    // rewardedAds에서 객체를 제거해도 얻는 메모리 이득이 미미하고,
    // 제거 후 재로드 시 객체 재생성 타이밍에 따른 사이드 이펙트가 발생할 수 있어
    // 호환성 유지 목적으로 메서드는 남기되 아무 작업도 하지 않음.
    result(nil);
}

#pragma mark - Helpers

- (ADXGdprType)getGdprType:(NSString *)type {
    NSDictionary *types = @{
            @"popup_debug" : @(ADXGdprTypePopupDebug),
            @"popup_location" : @(ADXGdprTypePopupLocation),
            @"direct_not_required" : @(ADXGdprTypeDirectNotRequired),
            @"direct_denied" : @(ADXGdprTypeDirectDenied),
            @"direct_confirm" : @(ADXGdprTypeDirectConfirm),
            @"direct_unknown" : @(ADXGdprTypeDirectUnknown)
    };
    return types[type] ? [types[type] integerValue] : ADXGdprTypeDirectUnknown;
}

- (ADXAdView *)retrieveAdView:(NSString *)adUnitId size:(NSString *)size {
    if (!self.adViews[adUnitId]) {
        UIViewController *rootVC = [self topViewController];
        if (!rootVC)
            return nil;
        CGSize bannerSize = [self adViewSize:size];
        ADXAdView *view = [[ADXAdView alloc] initWithAdUnitId:adUnitId
                                                       adSize:ADXAdSizeBanner
                                           rootViewController:rootVC];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        self.adViews[adUnitId] = view;
        [rootVC.view addSubview:view];
    }
    return self.adViews[adUnitId];
}

- (void)updatePositionAdView:(NSString *)adUnitId {
    ADXAdView *adView = self.adViews[adUnitId];
    if (!adView)
        return;
    UIView *superview = adView.superview;
    if (!superview)
        return;

    [NSLayoutConstraint deactivateConstraints:self.adViewConstraints[adUnitId]];

    if (![superview.subviews containsObject:self.safeAreaBackground]) {
        [self.safeAreaBackground removeFromSuperview];
        [superview insertSubview:self.safeAreaBackground belowSubview:adView];
    }
    self.safeAreaBackground.hidden = NO;

    UILayoutGuide *guide;
    if (@available(iOS 11.0, *)) {
        guide = superview.safeAreaLayoutGuide;
    } else {
        guide = superview.layoutMarginsGuide;
    }
    NSString *pos = self.adViewPositions[adUnitId] ?: @"bottom_center";

    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObject:[adView.widthAnchor constraintEqualToConstant:adView.bounds.size.width]];
    [constraints addObject:[adView.heightAnchor constraintEqualToConstant:adView.bounds.size.height]];

    NSDictionary *posMap = @{
            @"top_center" : @[ guide.topAnchor, guide.centerXAnchor ],
            @"top_left" : @[ guide.topAnchor, superview.leftAnchor ],
            @"top_right" : @[ guide.topAnchor, superview.rightAnchor ],
            @"center" : @[ guide.centerYAnchor, guide.centerXAnchor ],
            @"center_left" : @[ guide.centerYAnchor, superview.leftAnchor ],
            @"center_right" : @[ guide.centerYAnchor, superview.rightAnchor ],
            @"bottom_center" : @[ guide.bottomAnchor, guide.centerXAnchor ],
            @"bottom_left" : @[ guide.bottomAnchor, superview.leftAnchor ],
            @"bottom_right" : @[ guide.bottomAnchor, superview.rightAnchor ]
    };

    NSArray *anchors = posMap[pos] ?: posMap[@"bottom_center"];
    NSLayoutAnchor *yAnchor = anchors[0];
    NSLayoutAnchor *xAnchor = anchors[1];

    if ([pos containsString:@"top"])
        [constraints addObject:[adView.topAnchor constraintEqualToAnchor:yAnchor]];
    else if ([pos containsString:@"bottom"])
        [constraints addObject:[adView.bottomAnchor constraintEqualToAnchor:yAnchor]];
    else
        [constraints addObject:[adView.centerYAnchor constraintEqualToAnchor:yAnchor]];

    if ([pos containsString:@"left"])
        [constraints addObject:[adView.leftAnchor constraintEqualToAnchor:xAnchor]];
    else if ([pos containsString:@"right"])
        [constraints addObject:[adView.rightAnchor constraintEqualToAnchor:xAnchor]];
    else
        [constraints addObject:[adView.centerXAnchor constraintEqualToAnchor:xAnchor]];

    self.adViewConstraints[adUnitId] = constraints;
    [NSLayoutConstraint activateConstraints:constraints];
}

- (ADXInterstitialAd *)retrieveInterstitial:(NSString *)adUnitId {
    if (!self.interstitials[adUnitId])
        self.interstitials[adUnitId] = [[ADXInterstitialAd alloc] initWithAdUnitId:adUnitId];
    return self.interstitials[adUnitId];
}

- (ADXRewardedAd *)retrieveRewardedAd:(NSString *)adUnitId {
    if (!self.rewardedAds[adUnitId])
        self.rewardedAds[adUnitId] = [[ADXRewardedAd alloc] initWithAdUnitId:adUnitId];
    return self.rewardedAds[adUnitId];
}

- (UIViewController *)topViewController {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                if (@available(iOS 15.0, *)) {
                    window = scene.keyWindow;
                } else {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow) { window = w; break; }
                    }
                }
                if (!window) window = scene.windows.firstObject;
                break;
            }
        }
    }
    if (!window)
        window = [UIApplication sharedApplication].keyWindow;
    return [self topViewControllerWithRoot:window.rootViewController];
}

- (UIViewController *)topViewControllerWithRoot:(UIViewController *)root {
    if (!root)
        return nil;
    if ([root isKindOfClass:[UITabBarController class]])
        return [self topViewControllerWithRoot:((UITabBarController *)root)
                .selectedViewController];
    if ([root isKindOfClass:[UINavigationController class]])
        return [self topViewControllerWithRoot:((UINavigationController *)root)
                .visibleViewController];
    if (root.presentedViewController)
        return [self topViewControllerWithRoot:root.presentedViewController];
    return root;
}

- (CGSize)adViewSize:(NSString *)size {
    NSDictionary *sizes = @{
            @"320x50" : [NSValue valueWithCGSize:CGSizeMake(320, 50)],
            @"320x100" : [NSValue valueWithCGSize:CGSizeMake(320, 100)],
            @"300x250" : [NSValue valueWithCGSize:CGSizeMake(300, 250)],
            @"320x480" : [NSValue valueWithCGSize:CGSizeMake(320, 480)]
    };
    return sizes[size] ? [sizes[size] CGSizeValue] : CGSizeZero;
}

#pragma mark - Delegates
// Banner
- (void)adViewDidLoad:(ADXAdView *)v {
    [self.channel invokeMethod:@"BannerAd_onAdLoaded" arguments:nil];
}

- (void)adView:(ADXAdView *)v didFailToLoadWithError:(NSError *)e {
    [self.channel invokeMethod:@"BannerAd_onAdError"
                     arguments:@{@"error_code" : @(e.code)}];
}

- (void)adViewDidClick:(ADXAdView *)v {
    [self.channel invokeMethod:@"BannerAd_onAdClicked" arguments:nil];
}

// Interstitial
- (void)interstitialAdDidLoad:(ADXInterstitialAd *)v {
    [self.channel invokeMethod:@"Interstitial_onAdLoaded" arguments:nil];
}

- (void)interstitialAd:(ADXInterstitialAd *)v didFailToLoadWithError:(NSError *)e {
    [self.channel invokeMethod:@"Interstitial_onAdError"
                     arguments:@{@"error_code" : @(e.code)}];
}

- (void)interstitialAd:(ADXInterstitialAd *)v didFailToShowWithError:(NSError *)e {
    [self.channel invokeMethod:@"Interstitial_onAdFailedToShow" arguments:nil];
}

- (void)interstitialAdWillPresentScreen:(ADXInterstitialAd *)v {
    [self.channel invokeMethod:@"Interstitial_onAdImpression" arguments:nil];
}

- (void)interstitialAdDidDismissScreen:(ADXInterstitialAd *)v {
    [self.channel invokeMethod:@"Interstitial_onAdClosed" arguments:nil];
}

- (void)interstitialAdDidClick:(ADXInterstitialAd *)v {
    [self.channel invokeMethod:@"Interstitial_onAdClicked" arguments:nil];
}

- (void)interstitialAdWillDismissScreen:(ADXInterstitialAd *)v {
}

// Rewarded
- (void)rewardedAdDidLoad:(ADXRewardedAd *)v {
    [self.channel invokeMethod:@"RewardedAd_onAdLoaded" arguments:nil];
}

- (void)rewardedAd:(ADXRewardedAd *)v didFailToLoadWithError:(NSError *)e {
    [self.channel invokeMethod:@"RewardedAd_onAdError"
                     arguments:@{@"error_code" : @(e.code)}];
}

- (void)rewardedAd:(ADXRewardedAd *)v didFailToShowWithError:(NSError *)e {
    [self.channel invokeMethod:@"RewardedAd_onAdFailedToShow" arguments:nil];
}

- (void)rewardedAdWillPresentScreen:(ADXRewardedAd *)v {
    [self.channel invokeMethod:@"RewardedAd_onAdImpression" arguments:nil];
}

- (void)rewardedAdDidDismissScreen:(ADXRewardedAd *)v {
    [self.channel invokeMethod:@"RewardedAd_onAdClosed" arguments:nil];
}

- (void)rewardedAdDidRewardUser:(ADXRewardedAd *)v withReward:(ADXReward *)r {
    [self.channel invokeMethod:@"RewardedAd_onAdRewarded" arguments:nil];
}

- (void)rewardedAdDidClick:(ADXRewardedAd *)v {
    [self.channel invokeMethod:@"RewardedAd_onAdClicked" arguments:nil];
}

- (void)rewardedAdWillDismissScreen:(ADXRewardedAd *)v {
}

@end