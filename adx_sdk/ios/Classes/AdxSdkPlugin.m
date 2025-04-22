#import "AdxSdkPlugin.h"

@interface AdxSdkPlugin()<ADXAdViewDelegate, ADXInterstitialAdDelegate, ADXRewardedAdDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, ADXAdView *> *adViews;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *adViewPositions;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSLayoutConstraint *> *> *adViewConstraints;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ADXInterstitialAd *> *interstitials;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ADXRewardedAd *> *rewardedAds;

@property (nonatomic, strong) UIView *safeAreaBackground;

@end

@implementation AdxSdkPlugin

static FlutterMethodChannel *adxSdkChannel;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.adViews = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewPositions = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.adViewConstraints = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.interstitials = [NSMutableDictionary dictionaryWithCapacity: 2];
        self.rewardedAds = [NSMutableDictionary dictionaryWithCapacity: 2];

        self.safeAreaBackground = [[UIView alloc] init];
        self.safeAreaBackground.hidden = YES;
        self.safeAreaBackground.backgroundColor = UIColor.clearColor;
        self.safeAreaBackground.translatesAutoresizingMaskIntoConstraints = NO;
        self.safeAreaBackground.userInteractionEnabled = NO;

        [[self topViewController].view addSubview:self.safeAreaBackground];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    adxSdkChannel = [FlutterMethodChannel
            methodChannelWithName:@"adx_sdk"
                  binaryMessenger:[registrar messenger]];
    AdxSdkPlugin* instance = [[AdxSdkPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:adxSdkChannel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"call.method : %@", call.method);

    if ([@"initialize" isEqualToString: call.method]) {
        NSString *appId = call.arguments[@"app_id"];
        NSString *gdprType = call.arguments[@"gdpr_type"];
        NSString *pluginVersion = call.arguments[@"plugin_version"];
        NSArray *testDevices = call.arguments[@"test_devices"];

        NSLog(@"ADX Flutter Version : %@, ADX SDK Version : %@, App ID : %@, GdprType : %@, TestDevices : %@",
              pluginVersion, ADX_SDK_VERSION, appId, gdprType, testDevices);
        
        ADXGdprType adxGdprType = [self getGdprType:gdprType];

        // ADX SDK Initialize
        ADXConfiguration *configuration = [[ADXConfiguration alloc] initWithAppId:appId
                                                                         gdprType:adxGdprType
                                                                      testDevices:testDevices];
        
        configuration.logLevel = ADXLogLevelDebug;
        [[ADXSdk sharedInstance] initializeWithConfiguration:configuration
                                           completionHandler:^(BOOL resultFlag, ADXConsentState consentState) {
            NSLog(@"ADX Sdk Initialize");
            NSDictionary *data = @{@"result" : @(resultFlag), @"consent" : @(consentState)};
            result(data);
        }];
    } else if ([@"isInitialized" isEqualToString: call.method]) {
        BOOL isInitialized = [[ADXSdk sharedInstance] isInitialized];

        result(@(isInitialized));
    } else if ([@"setBannerPosition" isEqualToString: call.method]) {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *position = call.arguments[@"position"];

        self.adViewPositions[adUnitId] = position;
        [self updatePositionAdView:adUnitId];

        result(nil);
    } else if ([@"loadBannerAd" isEqualToString: call.method]) {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        NSString *size = call.arguments[@"size"];
        ADXAdView *adView = [self retrieveAdViewForadUnitId:adUnitId withSize:size];
        adView.delegate = self;

        [self updatePositionAdView:adUnitId];
        [adView loadAd];

        result(nil);
    } else if ([@"destroyBannerAd" isEqualToString: call.method]) {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        ADXAdView *adView = self.adViews[adUnitId];
        if (adView != nil) {
            adView.delegate = nil;
            [adView removeFromSuperview];
        }
        [self.adViews removeObjectForKey: adUnitId];
        [self.adViewPositions removeObjectForKey: adUnitId];
        [self.adViewConstraints removeObjectForKey: adUnitId];

        result(nil);
    } else if ([@"loadInterstitial" isEqualToString: call.method]) {
        ADXInterstitialAd *interstitial = [self retrieveInterstitialForadUnitId:call.arguments[@"ad_unit_id"]];
        interstitial.delegate = self;
        [interstitial loadAd];
        result(nil);
    } else if ([@"isInterstitialLoaded" isEqualToString: call.method]) {
        ADXInterstitialAd *interstitial = [self retrieveInterstitialForadUnitId:call.arguments[@"ad_unit_id"]];
        if (interstitial && interstitial.isLoaded) {
            result(@(YES));
        } else {
            result(@(NO));
        }
    } else if ([@"showInterstitial" isEqualToString: call.method]) {
        ADXInterstitialAd *interstitial = [self retrieveInterstitialForadUnitId:call.arguments[@"ad_unit_id"]];
        if (interstitial.isLoaded) {
            [interstitial showAdFromRootViewController: [self topViewController]];
        }
        result(nil);
    } else if ([@"destroyInterstitial" isEqualToString: call.method]) {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        ADXInterstitialAd *interstitial = self.interstitials[adUnitId];
        if (!interstitial) {
            interstitial.delegate = nil;
        }

        [self.interstitials removeObjectForKey: adUnitId];
        result(nil);
    } else if ([@"loadRewardedAd" isEqualToString: call.method]) {
        ADXRewardedAd *rewardedAd = [self retrieveRewardedAdForadUnitId:call.arguments[@"ad_unit_id"]];
        rewardedAd.delegate = self;
        NSString * userId = call.arguments[@"user_id"] ?: @"";;
        if([userId length]) {
            [rewardedAd setSSVOptionWithUserId:userId];
        }
        NSString * customData = call.arguments[@"custom_data"] ?: @"";;
        if([customData length]) {
            [rewardedAd setSSVOptionWithCustomData:customData];
        }
        [rewardedAd loadAd];
        result(nil);
    } else if ([@"isRewardedAdLoaded" isEqualToString: call.method]) {
        ADXRewardedAd *rewardedAd = [self retrieveRewardedAdForadUnitId:call.arguments[@"ad_unit_id"]];
        if (rewardedAd && rewardedAd.isLoaded) {
            result(@(YES));
        } else {
            result(@(NO));
        }
    } else if ([@"showRewardedAd" isEqualToString: call.method]) {
        ADXRewardedAd *rewardedAd = [self retrieveRewardedAdForadUnitId:call.arguments[@"ad_unit_id"]];
        if (rewardedAd.isLoaded) {
            NSString * userId = call.arguments[@"user_id"] ?: @"";;
            if([userId length]) {
                [rewardedAd setSSVOptionWithUserId:userId];
            }
            NSString * customData = call.arguments[@"custom_data"] ?: @"";;
            if([customData length]) {
                [rewardedAd setSSVOptionWithCustomData:customData];
            }
            [rewardedAd showAdFromRootViewController: [self topViewController]];
        }
        result(nil);
    } else if ([@"destroyRewardedAd" isEqualToString: call.method]) {
        NSString *adUnitId = call.arguments[@"ad_unit_id"];
        ADXRewardedAd *rewardedAd = self.rewardedAds[adUnitId];
        if (!rewardedAd) {
            rewardedAd.delegate = nil;
        }

        [self.rewardedAds removeObjectForKey: adUnitId];
        result(nil);
    }
}

- (ADXGdprType)getGdprType:(NSString *) gdprType {
    if ([@"popup_debug" isEqualToString:gdprType]) {
        return ADXGdprTypePopupDebug;
    } else if ([@"popup_location" isEqualToString:gdprType]) {
        return ADXGdprTypePopupLocation;
    } else if ([@"direct_not_required" isEqualToString:gdprType]) {
        return ADXGdprTypeDirectNotRequired;
    } else if ([@"direct_denied" isEqualToString:gdprType]) {
        return ADXGdprTypeDirectDenied;
    } else if ([@"direct_confirm" isEqualToString:gdprType]) {
        return ADXGdprTypeDirectConfirm;
    } else if ([@"direct_unknown" isEqualToString:gdprType]) {
        return ADXGdprTypeDirectUnknown;
    } else {
        [NSException raise: NSInvalidArgumentException format: @"Invalid GdprType"];
        return ADXGdprTypeDirectUnknown;
    }
}

- (ADXAdView *)retrieveAdViewForadUnitId:(NSString *)adUnitId withSize:(NSString *) size {
    ADXAdView *result = self.adViews[adUnitId];
    if (!result) {
        CGSize bannerSize = [self adViewSize:size];
        result = [[ADXAdView alloc] initWithAdUnitId:adUnitId adSize:ADXAdSizeBanner rootViewController:result.rootViewController];

        result.userInteractionEnabled = NO;
        result.translatesAutoresizingMaskIntoConstraints = NO;

        result.frame = CGRectMake(0, 0, bannerSize.width, bannerSize.height);

        self.adViews[adUnitId] = result;

        result.rootViewController = [self topViewController];
        [result.rootViewController.view addSubview:result];
    }

    return result;
}

- (void) updatePositionAdView:(NSString *)adUnitId {
    if (!adUnitId) {
        return;
    }

    ADXAdView *adView = self.adViews[adUnitId];
    NSString *position = self.adViewPositions[adUnitId];

    if (!adView) {
        return;
    }

    UIView *superview = adView.superview;
    if (!superview) {
        return;
    }

    NSArray<NSLayoutConstraint *> *activeConstraints = self.adViewConstraints[adUnitId];
    [NSLayoutConstraint deactivateConstraints: activeConstraints];

    if (![superview.subviews containsObject: self.safeAreaBackground]) {
        [self.safeAreaBackground removeFromSuperview];
        [superview insertSubview: self.safeAreaBackground belowSubview: adView];
    }

    [NSLayoutConstraint deactivateConstraints: self.safeAreaBackground.constraints];
    self.safeAreaBackground.hidden = NO;

    CGSize adViewSize = adView.bounds.size;

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithObject:
            [adView.heightAnchor constraintEqualToConstant: adViewSize.height]];

    UILayoutGuide *layoutGuide;
    if (@available(iOS 11.0, *)) {
        layoutGuide = superview.safeAreaLayoutGuide;
    } else {
        layoutGuide = superview.layoutMarginsGuide;
    }

    if (!position) {
        position = @"bottom_center";
    }

    NSLog(@"AdView position : %@", position);

    [constraints addObject: [adView.widthAnchor constraintEqualToConstant: adViewSize.width]];

    if ([@"top_center" isEqualToString:position]) {
        [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor]];
        [constraints addObject: [adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor]];
    } else if ([@"top_left" isEqualToString:position]) {
        [constraints addObject: [adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor]];
        [constraints addObject: [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]];
    } else if ([@"top_right" isEqualToString:position]) {
        [constraints addObject: [adView.topAnchor constraintEqualToAnchor: layoutGuide.topAnchor]];
        [constraints addObject: [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]];
    } else if ([@"center" isEqualToString:position]) {
        [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor]];
        [constraints addObject: [adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor]];
    } else if ([@"center_left" isEqualToString:position]) {
        [constraints addObject: [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]];
        [constraints addObject: [adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor]];
    } else if ([@"center_right" isEqualToString:position]) {
        [constraints addObject: [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]];
        [constraints addObject: [adView.centerYAnchor constraintEqualToAnchor: layoutGuide.centerYAnchor]];
    } else if ([@"bottom_center" isEqualToString:position]) {
        [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor]];
        [constraints addObject: [adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor]];
    } else if ([@"bottom_left" isEqualToString:position]) {
        [constraints addObject: [adView.leftAnchor constraintEqualToAnchor: superview.leftAnchor]];
        [constraints addObject: [adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor]];
    } else if ([@"bottom_right" isEqualToString:position]) {
        [constraints addObject: [adView.rightAnchor constraintEqualToAnchor: superview.rightAnchor]];
        [constraints addObject: [adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor]];
    } else {
        [constraints addObject: [adView.centerXAnchor constraintEqualToAnchor: layoutGuide.centerXAnchor]];
        [constraints addObject: [adView.bottomAnchor constraintEqualToAnchor: layoutGuide.bottomAnchor]];
    }

    self.adViewConstraints[adUnitId] = constraints;

    [NSLayoutConstraint activateConstraints: constraints];
}

- (ADXInterstitialAd *)retrieveInterstitialForadUnitId:(NSString *)adUnitId {
    ADXInterstitialAd *result = self.interstitials[adUnitId];
    if (!result) {
        result = [[ADXInterstitialAd alloc] initWithAdUnitId:adUnitId];
        self.interstitials[adUnitId] = result;
    }

    return result;
}

- (ADXRewardedAd *)retrieveRewardedAdForadUnitId:(NSString *)adUnitId {
    ADXRewardedAd *result = self.rewardedAds[adUnitId];
    if (!result) {
        result = [[ADXRewardedAd alloc] initWithAdUnitId:adUnitId];
        self.rewardedAds[adUnitId] = result;
    }

    return result;
}

- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

- (CGSize)adViewSize:(NSString *)adSize {
    if ([@"320x50" isEqualToString:adSize]) {
        return CGSizeMake(320.0f, 50.0f);
    } else if ([@"320x100" isEqualToString:adSize]) {
        return CGSizeMake(320.0f, 100.0f);
    } else if ([@"300x250" isEqualToString:adSize]) {
        return CGSizeMake(300.0f, 250.0f);
    } else if ([@"320x480" isEqualToString:adSize]) {
        return CGSizeMake(320.0f, 480.0f);
    } else {
        [NSException raise: NSInvalidArgumentException format: @"Invalid ad format"];
        return CGSizeZero;
    }
}

#pragma mark - ADXAdViewDelegate

- (void)adViewDidLoad:(nonnull ADXAdView *)adView {
    adView.userInteractionEnabled = YES;

    [adxSdkChannel invokeMethod: @"BannerAd_onAdLoaded" arguments: nil];
}

- (void)adView:(nonnull ADXAdView *)adView didFailToLoadWithError:(nonnull NSError *)error {
    NSDictionary *args = @{@"error_code" : [NSNumber numberWithLong:error.code]};

    [adxSdkChannel invokeMethod: @"BannerAd_onAdError" arguments: args];
}

#pragma mark - ADXInterstitialAdDelegate

- (void)interstitialAdDidLoad:(ADXInterstitialAd *)interstitialAd {
    [adxSdkChannel invokeMethod: @"Interstitial_onAdLoaded" arguments: nil];
}

- (void)interstitialAd:(ADXInterstitialAd *)interstitialAd didFailToLoadWithError:(NSError *)error {
    NSDictionary *args = @{@"error_code" : [NSNumber numberWithLong:error.code]};

    [adxSdkChannel invokeMethod: @"Interstitial_onAdError" arguments: args];
}

- (void)interstitialAd:(ADXInterstitialAd *)interstitialAd didFailToShowWithError:(NSError *)error {
    [adxSdkChannel invokeMethod: @"Interstitial_onAdFailedToShow" arguments: nil];
}

- (void)interstitialAdWillPresentScreen:(ADXInterstitialAd *)interstitialAd {
    [adxSdkChannel invokeMethod: @"Interstitial_onAdImpression" arguments: nil];
}

- (void)interstitialAdWillDismissScreen:(ADXInterstitialAd *)interstitialAd {
}

- (void)interstitialAdDidDismissScreen:(ADXInterstitialAd *)interstitialAd {
    [adxSdkChannel invokeMethod: @"Interstitial_onAdClosed" arguments: nil];
}

- (void)interstitialAdDidClick:(ADXInterstitialAd *)interstitialAd {
    [adxSdkChannel invokeMethod: @"Interstitial_onAdClicked" arguments: nil];
}

#pragma mark - ADXRewardedAdDelegate

- (void)rewardedAdDidLoad:(ADXRewardedAd *)rewardedAd {
    [adxSdkChannel invokeMethod: @"RewardedAd_onAdLoaded" arguments: nil];
}

- (void)rewardedAd:(ADXRewardedAd *)rewardedAd didFailToLoadWithError:(NSError *)error {
    NSDictionary *args = @{@"error_code" : [NSNumber numberWithLong:error.code]};

    [adxSdkChannel invokeMethod: @"RewardedAd_onAdError" arguments: args];
}

- (void)rewardedAd:(ADXRewardedAd *)rewardedAd didFailToShowWithError:(NSError *)error {
    [adxSdkChannel invokeMethod: @"RewardedAd_onAdFailedToShow" arguments: nil];
}

- (void)rewardedAdWillPresentScreen:(ADXRewardedAd *)rewardedAd {
    [adxSdkChannel invokeMethod: @"RewardedAd_onAdImpression" arguments: nil];
}

- (void)rewardedAdWillDismissScreen:(ADXRewardedAd *)rewardedAd {
    
}

- (void)rewardedAdDidDismissScreen:(ADXRewardedAd *)rewardedAd {
    [adxSdkChannel invokeMethod: @"RewardedAd_onAdClosed" arguments: nil];
}

- (void)rewardedAdDidRewardUser:(ADXRewardedAd *)rewardedAd withReward:(ADXReward *)reward {
    [adxSdkChannel invokeMethod: @"RewardedAd_onAdRewarded" arguments: nil];
}

- (void)rewardedAdDidClick:(ADXRewardedAd *)rewardedAd {
    [adxSdkChannel invokeMethod: @"RewardedAd_onAdClicked" arguments: nil];
}

@end
