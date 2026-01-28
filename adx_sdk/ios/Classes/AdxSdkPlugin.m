#import "AdxSdkPlugin.h"
#import "AdxSdkNativeAdViewFactory.h"

@interface AdxSdkPlugin() <ADXAdViewDelegate, ADXInterstitialAdDelegate, ADXRewardedAdDelegate>
@property (strong) NSMutableDictionary<NSString *, ADXAdView *> *adViews;
@property (strong) NSMutableDictionary<NSString *, NSString *> *adViewPositions;
@property (strong) NSMutableDictionary<NSString *, NSArray<NSLayoutConstraint *> *> *adViewConstraints;
@property (strong) NSMutableDictionary<NSString *, ADXInterstitialAd *> *interstitials;
@property (strong) NSMutableDictionary<NSString *, ADXRewardedAd *> *rewardedAds;
@property (strong) UIView *safeAreaBackground;
@end

@implementation AdxSdkPlugin

static FlutterMethodChannel *adxSdkChannel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    adxSdkChannel = [FlutterMethodChannel methodChannelWithName:@"adx_sdk" binaryMessenger:[registrar messenger]];
    AdxSdkPlugin* instance = [[AdxSdkPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:adxSdkChannel];
    
    AdxSdkNativeAdViewFactory *nativeAdViewFactory = [[AdxSdkNativeAdViewFactory alloc] initWithMessenger:[registrar messenger]];
    [registrar registerViewFactory:nativeAdViewFactory withId:@"adx_sdk/native_ad_view"];
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
        [[self topViewController].view addSubview:_safeAreaBackground];
    }
    return self;
}

+ (ADXSdk *)shared { return [ADXSdk sharedInstance]; }

+ (void)sendEventWithName:(NSString *)name arguments:(NSDictionary *)arguments channel:(FlutterMethodChannel *)channel {
    [channel invokeMethod:name arguments:arguments];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"call.method : %@", call.method);
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"handle_%@:result:", call.method]);
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:call withObject:result];
#pragma clang diagnostic pop
    } else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Method Handlers

- (void)handle_initialize:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *appId = call.arguments[@"app_id"];
    NSArray *testDevices = call.arguments[@"test_devices"];
    ADXGdprType gdpr = [self getGdprType:call.arguments[@"gdpr_type"]];
    
    ADXConfiguration *config = [[ADXConfiguration alloc] initWithAppId:appId gdprType:gdpr testDevices:testDevices];
    config.logLevel = ADXLogLevelDebug;
    
    [[ADXSdk sharedInstance] initializeWithConfiguration:config completionHandler:^(BOOL resultFlag, ADXConsentState consentState) {
        result(@{@"result": @(resultFlag), @"consent": @(consentState)});
    }];
}

- (void)handle_isInitialized:(FlutterMethodCall*)call result:(FlutterResult)result {
    result(@([[ADXSdk sharedInstance] isInitialized]));
}

- (void)handle_setBannerPosition:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    self.adViewPositions[adUnitId] = call.arguments[@"position"];
    [self updatePositionAdView:adUnitId];
    result(nil);
}

- (void)handle_loadBannerAd:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    ADXAdView *adView = [self retrieveAdView:adUnitId size:call.arguments[@"size"]];
    adView.delegate = self;
    [self updatePositionAdView:adUnitId];
    [adView loadAd];
    result(nil);
}

- (void)handle_destroyBannerAd:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    ADXAdView *adView = self.adViews[adUnitId];
    if (adView) {
        adView.delegate = nil;
        [adView removeFromSuperview];
        [self.adViews removeObjectForKey:adUnitId];
        [self.adViewPositions removeObjectForKey:adUnitId];
        [self.adViewConstraints removeObjectForKey:adUnitId];
    }
    result(nil);
}

- (void)handle_loadInterstitial:(FlutterMethodCall*)call result:(FlutterResult)result {
    ADXInterstitialAd *ad = [self retrieveInterstitial:call.arguments[@"ad_unit_id"]];
    ad.delegate = self;
    [ad loadAd];
    result(nil);
}

- (void)handle_isInterstitialLoaded:(FlutterMethodCall*)call result:(FlutterResult)result {
    ADXInterstitialAd *ad = [self retrieveInterstitial:call.arguments[@"ad_unit_id"]];
    (ad && ad.isLoaded) ? result(@(YES)) : result(@(NO));
}

- (void)handle_showInterstitial:(FlutterMethodCall*)call result:(FlutterResult)result {
    ADXInterstitialAd *ad = [self retrieveInterstitial:call.arguments[@"ad_unit_id"]];
    if (ad.isLoaded) [ad showAdFromRootViewController:[self topViewController]];
    result(nil);
}

- (void)handle_destroyInterstitial:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    if (self.interstitials[adUnitId]) {
        self.interstitials[adUnitId].delegate = nil;
        [self.interstitials removeObjectForKey:adUnitId];
    }
    result(nil);
}

- (void)handle_loadRewardedAd:(FlutterMethodCall*)call result:(FlutterResult)result {
    ADXRewardedAd *ad = [self retrieveRewardedAd:call.arguments[@"ad_unit_id"]];
    ad.delegate = self;
    NSString *userId = call.arguments[@"user_id"];
    NSString *customData = call.arguments[@"custom_data"];
    if (userId.length) [ad setSSVOptionWithUserId:userId];
    if (customData.length) [ad setSSVOptionWithCustomData:customData];
    [ad loadAd];
    result(nil);
}

- (void)handle_isRewardedAdLoaded:(FlutterMethodCall*)call result:(FlutterResult)result {
    ADXRewardedAd *ad = [self retrieveRewardedAd:call.arguments[@"ad_unit_id"]];
    (ad && ad.isLoaded) ? result(@(YES)) : result(@(NO));
}

- (void)handle_showRewardedAd:(FlutterMethodCall*)call result:(FlutterResult)result {
    ADXRewardedAd *ad = [self retrieveRewardedAd:call.arguments[@"ad_unit_id"]];
    if (ad.isLoaded) {
        if (call.arguments[@"user_id"]) [ad setSSVOptionWithUserId:call.arguments[@"user_id"]];
        if (call.arguments[@"custom_data"]) [ad setSSVOptionWithCustomData:call.arguments[@"custom_data"]];
        [ad showAdFromRootViewController:[self topViewController]];
    }
    result(nil);
}

- (void)handle_destroyRewardedAd:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *adUnitId = call.arguments[@"ad_unit_id"];
    if (self.rewardedAds[adUnitId]) {
        self.rewardedAds[adUnitId].delegate = nil;
        [self.rewardedAds removeObjectForKey:adUnitId];
    }
    result(nil);
}

#pragma mark - Helpers

- (ADXGdprType)getGdprType:(NSString *)type {
    NSDictionary *types = @{
        @"popup_debug": @(ADXGdprTypePopupDebug),
        @"popup_location": @(ADXGdprTypePopupLocation),
        @"direct_not_required": @(ADXGdprTypeDirectNotRequired),
        @"direct_denied": @(ADXGdprTypeDirectDenied),
        @"direct_confirm": @(ADXGdprTypeDirectConfirm),
        @"direct_unknown": @(ADXGdprTypeDirectUnknown)
    };
    return types[type] ? [types[type] integerValue] : ADXGdprTypeDirectUnknown;
}

- (ADXAdView *)retrieveAdView:(NSString *)adUnitId size:(NSString *)size {
    if (!self.adViews[adUnitId]) {
        CGSize bannerSize = [self adViewSize:size];
        ADXAdView *view = [[ADXAdView alloc] initWithAdUnitId:adUnitId adSize:ADXAdSizeBanner rootViewController:[self topViewController]];
        view.userInteractionEnabled = NO;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        view.frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);
        self.adViews[adUnitId] = view;
        [[self topViewController].view addSubview:view];
    }
    return self.adViews[adUnitId];
}

- (void)updatePositionAdView:(NSString *)adUnitId {
    ADXAdView *adView = self.adViews[adUnitId];
    UIView *superview = adView.superview;
    if (!adView || !superview) return;
    
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
        @"top_center": @[guide.topAnchor, guide.centerXAnchor],
        @"top_left": @[guide.topAnchor, superview.leftAnchor],
        @"top_right": @[guide.topAnchor, superview.rightAnchor],
        @"center": @[guide.centerYAnchor, guide.centerXAnchor],
        @"center_left": @[guide.centerYAnchor, superview.leftAnchor],
        @"center_right": @[guide.centerYAnchor, superview.rightAnchor],
        @"bottom_center": @[guide.bottomAnchor, guide.centerXAnchor],
        @"bottom_left": @[guide.bottomAnchor, superview.leftAnchor],
        @"bottom_right": @[guide.bottomAnchor, superview.rightAnchor]
    };
    
    NSArray *anchors = posMap[pos] ?: posMap[@"bottom_center"];
    NSLayoutAnchor *yAnchor = anchors[0];
    NSLayoutAnchor *xAnchor = anchors[1];
    
    // Vertical
    if ([pos containsString:@"top"]) [constraints addObject:[adView.topAnchor constraintEqualToAnchor:yAnchor]];
    else if ([pos containsString:@"bottom"]) [constraints addObject:[adView.bottomAnchor constraintEqualToAnchor:yAnchor]];
    else [constraints addObject:[adView.centerYAnchor constraintEqualToAnchor:yAnchor]];
    
    // Horizontal
    if ([pos containsString:@"left"]) [constraints addObject:[adView.leftAnchor constraintEqualToAnchor:xAnchor]];
    else if ([pos containsString:@"right"]) [constraints addObject:[adView.rightAnchor constraintEqualToAnchor:xAnchor]];
    else [constraints addObject:[adView.centerXAnchor constraintEqualToAnchor:xAnchor]];
    
    self.adViewConstraints[adUnitId] = constraints;
    [NSLayoutConstraint activateConstraints:constraints];
}

- (ADXInterstitialAd *)retrieveInterstitial:(NSString *)id {
    if (!self.interstitials[id]) self.interstitials[id] = [[ADXInterstitialAd alloc] initWithAdUnitId:id];
    return self.interstitials[id];
}

- (ADXRewardedAd *)retrieveRewardedAd:(NSString *)id {
    if (!self.rewardedAds[id]) self.rewardedAds[id] = [[ADXRewardedAd alloc] initWithAdUnitId:id];
    return self.rewardedAds[id];
}

- (UIViewController*)topViewController {
    return [self topViewControllerWithRoot:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRoot:(UIViewController*)root {
    if ([root isKindOfClass:[UITabBarController class]]) return [self topViewControllerWithRoot:((UITabBarController*)root).selectedViewController];
    if ([root isKindOfClass:[UINavigationController class]]) return [self topViewControllerWithRoot:((UINavigationController*)root).visibleViewController];
    if (root.presentedViewController) return [self topViewControllerWithRoot:root.presentedViewController];
    return root;
}

- (CGSize)adViewSize:(NSString *)size {
    NSDictionary *sizes = @{@"320x50": [NSValue valueWithCGSize:CGSizeMake(320, 50)],
                            @"320x100": [NSValue valueWithCGSize:CGSizeMake(320, 100)],
                            @"300x250": [NSValue valueWithCGSize:CGSizeMake(300, 250)],
                            @"320x480": [NSValue valueWithCGSize:CGSizeMake(320, 480)]};
    return sizes[size] ? [sizes[size] CGSizeValue] : CGSizeZero;
}

#pragma mark - Delegates
// Banner
- (void)adViewDidLoad:(ADXAdView *)v { [adxSdkChannel invokeMethod:@"BannerAd_onAdLoaded" arguments:nil]; }
- (void)adView:(ADXAdView *)v didFailToLoadWithError:(NSError *)e { [adxSdkChannel invokeMethod:@"BannerAd_onAdError" arguments:@{@"error_code": @(e.code)}]; }
- (void)adViewDidClick:(ADXAdView *)v { [adxSdkChannel invokeMethod:@"BannerAd_onAdClicked" arguments:nil]; }

// Interstitial
- (void)interstitialAdDidLoad:(ADXInterstitialAd *)v { [adxSdkChannel invokeMethod:@"Interstitial_onAdLoaded" arguments:nil]; }
- (void)interstitialAd:(ADXInterstitialAd *)v didFailToLoadWithError:(NSError *)e { [adxSdkChannel invokeMethod:@"Interstitial_onAdError" arguments:@{@"error_code": @(e.code)}]; }
- (void)interstitialAd:(ADXInterstitialAd *)v didFailToShowWithError:(NSError *)e { [adxSdkChannel invokeMethod:@"Interstitial_onAdFailedToShow" arguments:nil]; }
- (void)interstitialAdWillPresentScreen:(ADXInterstitialAd *)v { [adxSdkChannel invokeMethod:@"Interstitial_onAdImpression" arguments:nil]; }
- (void)interstitialAdDidDismissScreen:(ADXInterstitialAd *)v { [adxSdkChannel invokeMethod:@"Interstitial_onAdClosed" arguments:nil]; }
- (void)interstitialAdDidClick:(ADXInterstitialAd *)v { [adxSdkChannel invokeMethod:@"Interstitial_onAdClicked" arguments:nil]; }
- (void)interstitialAdWillDismissScreen:(ADXInterstitialAd *)v {}

// Rewarded
- (void)rewardedAdDidLoad:(ADXRewardedAd *)v { [adxSdkChannel invokeMethod:@"RewardedAd_onAdLoaded" arguments:nil]; }
- (void)rewardedAd:(ADXRewardedAd *)v didFailToLoadWithError:(NSError *)e { [adxSdkChannel invokeMethod:@"RewardedAd_onAdError" arguments:@{@"error_code": @(e.code)}]; }
- (void)rewardedAd:(ADXRewardedAd *)v didFailToShowWithError:(NSError *)e { [adxSdkChannel invokeMethod:@"RewardedAd_onAdFailedToShow" arguments:nil]; }
- (void)rewardedAdWillPresentScreen:(ADXRewardedAd *)v { [adxSdkChannel invokeMethod:@"RewardedAd_onAdImpression" arguments:nil]; }
- (void)rewardedAdDidDismissScreen:(ADXRewardedAd *)v { [adxSdkChannel invokeMethod:@"RewardedAd_onAdClosed" arguments:nil]; }
- (void)rewardedAdDidRewardUser:(ADXRewardedAd *)v withReward:(ADXReward *)r { [adxSdkChannel invokeMethod:@"RewardedAd_onAdRewarded" arguments:nil]; }
- (void)rewardedAdDidClick:(ADXRewardedAd *)v { [adxSdkChannel invokeMethod:@"RewardedAd_onAdClicked" arguments:nil]; }
- (void)rewardedAdWillDismissScreen:(ADXRewardedAd *)v {}

@end


