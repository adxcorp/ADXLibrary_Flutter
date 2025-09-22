import 'package:flutter/services.dart';
import 'package:adx_sdk/src/adx_sdk_listener.dart';
import 'package:adx_sdk/src/adx_sdk_common.dart';

export 'package:adx_sdk/src/adx_sdk_listener.dart';
export 'package:adx_sdk/src/adx_sdk_common.dart';

class AdxSdk {
  static const version = "1.0.8";

  static const channel = MethodChannel('adx_sdk');

  static BannerListener? _bannerListener;
  static InterstitialAdListener? _interstitialAdListener;
  static RewardedAdListener? _rewardedAdListener;

  AdxSdk();

  static Future<AdxInitResult> initialize(String appId, String gdprType, List<String> testDevices) async {

    channel.setMethodCallHandler((MethodCall call) async {
      var method = call.method;
      var arguments = call.arguments;
      print("method : $method");

      if (method == "BannerAd_onAdLoaded") {
        _bannerListener?.onAdLoaded();
      } else if (method == "BannerAd_onAdError") {
        _bannerListener?.onAdError(arguments['error_code']);
      } else if (method == "BannerAd_onAdClicked") {
        _bannerListener?.onAdClicked();
      }

      if (method == "Interstitial_onAdLoaded") {
        _interstitialAdListener?.onAdLoaded();
      } else if (method == "Interstitial_onAdError") {
        _interstitialAdListener?.onAdError(arguments['error_code']);
      } else if (method == "Interstitial_onAdImpression") {
        _interstitialAdListener?.onAdImpression();
      } else if (method == "Interstitial_onAdClicked") {
        _interstitialAdListener?.onAdClicked();
      } else if (method == "Interstitial_onAdClosed") {
        _interstitialAdListener?.onAdClosed();
      } else if (method == "Interstitial_onAdFailedToShow") {
        _interstitialAdListener?.onAdFailedToShow();
      }

      if (method == "RewardedAd_onAdLoaded") {
        _rewardedAdListener?.onAdLoaded();
      } else if (method == "RewardedAd_onAdError") {
        _rewardedAdListener?.onAdError(arguments['error_code']);
      } else if (method == "RewardedAd_onAdImpression") {
        _rewardedAdListener?.onAdImpression();
      } else if (method == "RewardedAd_onAdClicked") {
        _rewardedAdListener?.onAdClicked();
      } else if (method == "RewardedAd_onAdRewarded") {
        _rewardedAdListener?.onAdRewarded();
      } else if (method == "RewardedAd_onAdClosed") {
        _rewardedAdListener?.onAdClosed();
      } else if (method == "RewardedAd_onAdFailedToShow") {
        _rewardedAdListener?.onAdFailedToShow();
      }
    });

    var res = await channel.invokeMethod('initialize', {
      'plugin_version': version,
      'app_id': appId,
      'gdpr_type': gdprType,
      'test_devices': testDevices
    });

    var result = res["result"];
    var consent = res["consent"];

    return AdxInitResult(result, consent);
  }

  static Future<bool?> isInitialized() {
    return channel.invokeMethod('isInitialized');
  }

  static void setBannerPosition(String adUnitId, String position) {
    channel.invokeMethod('setBannerPosition', {
      'ad_unit_id': adUnitId,
      'position': position
    });
  }

  static void loadBannerAd(String adUnitId, String size) {
    channel.invokeMethod('loadBannerAd', {
      'ad_unit_id': adUnitId,
      'size': size
    });
  }

  static void destroyBannerAd(String adUnitId) {
    channel.invokeMethod('destroyBannerAd', {
      'ad_unit_id': adUnitId,
    });
  }

  static void loadInterstitial(String adUnitId) {
    channel.invokeMethod('loadInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  static void showInterstitial(String adUnitId) {
    channel.invokeMethod('showInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  static void destroyInterstitial(String adUnitId) {
    channel.invokeMethod('destroyInterstitial', {
      'ad_unit_id': adUnitId,
    });
  }

  static Future<bool?> isInterstitialLoaded(String adUnitId) {
    return channel.invokeMethod('isInterstitialLoaded', {
      'ad_unit_id': adUnitId,
    });
  }

  static void loadRewardedAd(String adUnitId, {String? ssvUserId, String? ssvCustomData}) {
    channel.invokeMethod('loadRewardedAd', {
      'ad_unit_id': adUnitId,
      'user_id': ssvUserId ?? '',
      'custom_data': ssvCustomData ?? ''
    });
  }

  static void showRewardedAd(String adUnitId, {String? ssvUserId, String? ssvCustomData}) {
    channel.invokeMethod('showRewardedAd', {
      'ad_unit_id': adUnitId,
      'user_id': ssvUserId ?? '',
      'custom_data': ssvCustomData ?? ''
    });
  }

  static Future<bool?> isRewardedAdLoaded(String adUnitId) {
    return channel.invokeMethod('isRewardedAdLoaded', {
      'ad_unit_id': adUnitId,
    });
  }

  static void destroyRewardedAd(String adUnitId) {
    channel.invokeMethod('destroyRewardedAd', {
      'ad_unit_id': adUnitId,
    });
  }

  static void setBannerListener(BannerListener bannerListener) {
    _bannerListener = bannerListener;
  }

  static void setInterstitialListener(InterstitialAdListener interstitialAdListener) {
    _interstitialAdListener = interstitialAdListener;
  }

  static void setRewardedAdListener(RewardedAdListener rewardedAdListener) {
    _rewardedAdListener = rewardedAdListener;
  }
}