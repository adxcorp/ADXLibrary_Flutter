package com.adxcorp.adx_sdk;

import android.app.Activity;
import android.content.Context;
import android.text.TextUtils;
import android.util.Log;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;

import com.adxcorp.ads.ADXConfiguration;
import com.adxcorp.ads.ADXSdk;
import com.adxcorp.ads.BannerAd;
import com.adxcorp.ads.InterstitialAd;
import com.adxcorp.ads.RewardedAd;
import com.adxcorp.ads.common.AdConstants;
import com.adxcorp.ads.mediation.util.DisplayUtil;
import com.adxcorp.gdpr.ADXGDPR;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** AdxSdkPlugin */
public class AdxSdkPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel defaultChannel;

  private static String TAG = "AdxFlutter";
  private Context context;
  private ActivityPluginBinding lastActivityPluginBinding;

  private final Map<String, BannerAd> mBannerAds = new HashMap<>(2);
  private final Map<String, String> mBannerAdPositions = new HashMap<>(2);
  private final Map<String, InterstitialAd> mInterstitialAds = new HashMap<>(2);
  private final Map<String, RewardedAd> mRewardedAds = new HashMap<>(2);

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    defaultChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "adx_sdk");
    defaultChannel.setMethodCallHandler(this);

    context = flutterPluginBinding.getApplicationContext();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("initialize")) {

      String pluginVersion = call.argument("plugin_version");
      String appId = call.argument("app_id");
      String gdprType = call.argument("gdpr_type");
      List<String> testDevices = call.argument("test_devices");

      Log.d(TAG, "ADX Flutter Version : " + pluginVersion
              + ", ADX SDK Version : " + ADXGDPR.ADX_SDK_VERSION
              + ", App ID : " + appId
              + ", GdprType : " + gdprType
              + ", TestDevices : " + testDevices);

      ADXConfiguration.GdprType gdprTypeValue = getGdprType(gdprType);

      // ADX 초기화 관련 설정
      ADXConfiguration adxConfiguration = new ADXConfiguration.Builder()
              .setAppId(appId)
              .setGdprType(gdprTypeValue)
              .setTestDeviceIds(testDevices) // UMP Test Device
              .build();

      ADXSdk.getInstance().initialize(getCurrentActivity(), adxConfiguration, new ADXSdk.OnInitializedListener() {
        @Override
        public void onCompleted(boolean resultFlag, ADXGDPR.ADXConsentState adxConsentState) {
          // 광고 초기화 완료
          HashMap<String, Object> dataMap = new HashMap<String,Object>();
          dataMap.put("result", resultFlag);

          int consent = 0;
          switch (adxConsentState) {
            case ADXConsentStateUnknown:
              break;
            case ADXConsentStateNotRequired:
              consent = 1;
              break;
            case ADXConsentStateDenied:
              consent = 2;
              break;
            case ADXConsentStateConfirm:
              consent = 3;
              break;
          }
          dataMap.put("consent", consent);

          result.success(dataMap);
        }
      });

    } else if (call.method.equals("isInitialized")) {

      result.success(ADXSdk.getInstance().isInitialized());

    } else if (call.method.equals("setBannerPosition")) {

      String adUnitId = call.argument("ad_unit_id");
      String position = call.argument("position");

      mBannerAdPositions.put(adUnitId, position);
      updatePositionBannerAd(adUnitId);

      result.success(null);

    } else if (call.method.equals("loadBannerAd")) {

      String adUnitId = call.argument("ad_unit_id");
      String size = call.argument("size");

      BannerAd bannerAd = retrieveBannerAd(adUnitId, size);

      if (bannerAd.getParent() == null) {
        Activity currentActivity = getCurrentActivity();
        RelativeLayout relativeLayout = new RelativeLayout(currentActivity);
        currentActivity.addContentView(relativeLayout, new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.MATCH_PARENT));

        relativeLayout.addView(bannerAd);
      }

      updatePositionBannerAd(adUnitId);

      bannerAd.loadAd();

      result.success(null);

    } else if (call.method.equals("destroyBannerAd")) {

      String adUnitId = call.argument("ad_unit_id");

      if (mBannerAds.containsKey(adUnitId)) {
        BannerAd bannerAd = mBannerAds.get(adUnitId);

        if (bannerAd != null) {
          ViewParent parent = bannerAd.getParent();
          if (parent instanceof ViewGroup) {
            ((ViewGroup) parent).removeView(bannerAd);
          }

          bannerAd.destroy();
          bannerAd = null;
        }

        mBannerAds.remove(adUnitId);
      }

      mBannerAdPositions.remove(adUnitId);

      result.success(null);

    } else if (call.method.equals("loadInterstitial")) {

      String adUnitId = call.argument("ad_unit_id");

      InterstitialAd interstitial = retrieveInterstitial(adUnitId);
      interstitial.loadAd();

      result.success(null);

    } else if (call.method.equals("isInterstitialLoaded")) {

      String adUnitId = call.argument("ad_unit_id");

      if (mInterstitialAds.containsKey(adUnitId)) {
        InterstitialAd interstitial = retrieveInterstitial(adUnitId);
        result.success(interstitial.isLoaded());
      } else {
        result.success(false);
      }

    } else if (call.method.equals("showInterstitial")) {

      String adUnitId = call.argument("ad_unit_id");

      if (mInterstitialAds.containsKey(adUnitId)) {
        InterstitialAd interstitial = retrieveInterstitial(adUnitId);
        interstitial.show();
      }

      result.success(null);

    } else if (call.method.equals("destroyInterstitial")) {

      String adUnitId = call.argument("ad_unit_id");

      if (mInterstitialAds.containsKey(adUnitId)) {
        InterstitialAd interstitial = retrieveInterstitial(adUnitId);
        if (interstitial != null) {
          interstitial.destroy();
          interstitial = null;
        }

        mInterstitialAds.remove(adUnitId);
      }

      result.success(null);

    } else if (call.method.equals("loadRewardedAd")) {

      String adUnitId = call.argument("ad_unit_id");

      RewardedAd rewardedAd = retrieveRewardedAd(adUnitId);
      rewardedAd.loadAd();

      result.success(null);

    } else if (call.method.equals("isRewardedAdLoaded")) {

      String adUnitId = call.argument("ad_unit_id");

      if (mRewardedAds.containsKey(adUnitId)) {
        RewardedAd rewardedAd = retrieveRewardedAd(adUnitId);

        result.success(rewardedAd.isLoaded());
      } else {
        result.success(false);
      }

    } else if (call.method.equals("showRewardedAd")) {

      String adUnitId = call.argument("ad_unit_id");

      if (mRewardedAds.containsKey(adUnitId)) {
        RewardedAd rewardedAd = retrieveRewardedAd(adUnitId);
        rewardedAd.show();
      }

      result.success(null);

    } else if (call.method.equals("setUserIdForSSV")) {
      String adUnitId = call.argument("ad_unit_id");
      String userId = call.argument("user_id");
      if (mRewardedAds.containsKey(adUnitId) && userId.isEmpty() == false) {
        RewardedAd rewardedAd = retrieveRewardedAd(adUnitId);
        rewardedAd.setUserIdForSSV(userId);
      }
      result.success(null);
    } else if (call.method.equals("setCustomDataForSSV")) {
      String adUnitId = call.argument("ad_unit_id");
      String customData = call.argument("custom_data");
      if (mRewardedAds.containsKey(adUnitId) && customData.isEmpty() == false) {
        RewardedAd rewardedAd = retrieveRewardedAd(adUnitId);
        rewardedAd.setCustomDataForSSV(customData);
      }
      result.success(null);
    } else if (call.method.equals("destroyRewardedAd")) {
      String adUnitId = call.argument("ad_unit_id");

      if (mRewardedAds.containsKey(adUnitId)) {
        RewardedAd rewardedAd = retrieveRewardedAd(adUnitId);
        if (rewardedAd != null) {
          rewardedAd.destroy();
          rewardedAd = null;
        }

        mRewardedAds.remove(adUnitId);
      }

      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  @NonNull
  private static ADXConfiguration.GdprType getGdprType(String gdprType) {
    ADXConfiguration.GdprType gdprTypeValue = ADXConfiguration.GdprType.DIRECT_UNKNOWN;

    if (!TextUtils.isEmpty(gdprType)) {
      if (gdprType.equals("popup_location")) {
        gdprTypeValue = ADXConfiguration.GdprType.POPUP_LOCATION;
      } else if (gdprType.equals("popup_debug")) {
        gdprTypeValue = ADXConfiguration.GdprType.POPUP_DEBUG;
      } else if (gdprType.equals("direct_confirm")) {
        gdprTypeValue = ADXConfiguration.GdprType.DIRECT_CONFIRM;
      } else if (gdprType.equals("direct_denied")) {
        gdprTypeValue = ADXConfiguration.GdprType.DIRECT_DENIED;
      } else if (gdprType.equals("direct_not_required")) {
        gdprTypeValue = ADXConfiguration.GdprType.DIRECT_NOT_REQUIRED;
      } else if (gdprType.equals("direct_unknown")) {
        gdprTypeValue = ADXConfiguration.GdprType.DIRECT_UNKNOWN;
      }
    }
    return gdprTypeValue;
  }

  private void updatePositionBannerAd(String adUnitId) {
    BannerAd bannerAd = mBannerAds.get(adUnitId);
    String position = mBannerAdPositions.get(adUnitId);

    if (bannerAd == null) {
      return;
    }

    if (TextUtils.isEmpty(position)) {
      position = "bottom_center";
    }

    RelativeLayout.LayoutParams prelayoutParams = (RelativeLayout.LayoutParams) bannerAd.getLayoutParams();

    RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(prelayoutParams.width,
            prelayoutParams.height);

    switch (position) {
      case "top_center":
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        layoutParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
        break;
      case "top_left":
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
        break;
      case "top_right":
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_TOP);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        break;
      case "center":
        layoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);
        break;
      case "center_left":
        layoutParams.addRule(RelativeLayout.CENTER_VERTICAL);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
        break;
      case "center_right":
        layoutParams.addRule(RelativeLayout.CENTER_VERTICAL);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        break;
      case "bottom_center":
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        layoutParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
        break;
      case "bottom_left":
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
        break;
      case "bottom_right":
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_RIGHT);
        break;
      default:
        layoutParams.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
        layoutParams.addRule(RelativeLayout.CENTER_HORIZONTAL);
        break;
    }

    bannerAd.setLayoutParams(layoutParams);
  }

  private BannerAd retrieveBannerAd(String adUnitId, String size) {
    BannerAd bannerAd = mBannerAds.get(adUnitId);
    if (bannerAd == null) {
      RelativeLayout.LayoutParams layoutParams = new RelativeLayout.LayoutParams(
              ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);

      switch (size) {
        case "320x50":
          bannerAd = new BannerAd(getCurrentActivity(), adUnitId, AdConstants.BANNER_AD_SIZE.AD_SIZE_320x50);
          layoutParams = new RelativeLayout.LayoutParams(DisplayUtil.dpToPx(context, 320),
                  DisplayUtil.dpToPx(context, 50));
          break;
        case "320x100":
          bannerAd = new BannerAd(getCurrentActivity(), adUnitId, AdConstants.BANNER_AD_SIZE.AD_SIZE_320x100);
          layoutParams = new RelativeLayout.LayoutParams(DisplayUtil.dpToPx(context, 320),
                  DisplayUtil.dpToPx(context, 100));
          break;
        case "300x250":
          bannerAd = new BannerAd(getCurrentActivity(), adUnitId, AdConstants.BANNER_AD_SIZE.AD_SIZE_300x250);
          layoutParams = new RelativeLayout.LayoutParams(DisplayUtil.dpToPx(context, 300),
                  DisplayUtil.dpToPx(context, 250));
          break;
        case "728x90":
          bannerAd = new BannerAd(getCurrentActivity(), adUnitId, AdConstants.BANNER_AD_SIZE.AD_SIZE_728x90);
          layoutParams = new RelativeLayout.LayoutParams(DisplayUtil.dpToPx(context, 728),
                  DisplayUtil.dpToPx(context, 90));
          break;
      }
      bannerAd.setLayoutParams(layoutParams);

      bannerAd.setBannerListener(new BannerAd.BannerListener() {
        @Override
        public void onAdLoaded() {
          defaultChannel.invokeMethod("BannerAd_onAdLoaded", null);
        }

        @Override
        public void onAdError(int errorCode) {
          Map<String, Object> params = new HashMap<>();
          params.put("error_code", errorCode);
          defaultChannel.invokeMethod("BannerAd_onAdError", params);
        }

        @Override
        public void onAdClicked() {
          defaultChannel.invokeMethod("BannerAd_onAdClicked", null);
        }
      });

      mBannerAds.put(adUnitId, bannerAd);
    }

    return bannerAd;
  }

  private com.adxcorp.ads.InterstitialAd retrieveInterstitial(String adUnitId) {
    com.adxcorp.ads.InterstitialAd interstitialAd = mInterstitialAds.get(adUnitId);
    if (interstitialAd == null) {
      interstitialAd = new com.adxcorp.ads.InterstitialAd(getCurrentActivity(), adUnitId);
      interstitialAd.setInterstitialListener(new InterstitialAd.InterstitialListener() {
        @Override
        public void onAdLoaded() {
          defaultChannel.invokeMethod("Interstitial_onAdLoaded", null);
        }

        @Override
        public void onAdError(int errorCode) {
          Map<String, Object> params = new HashMap<>();
          params.put("error_code", errorCode);
          defaultChannel.invokeMethod("Interstitial_onAdError", params);
        }

        @Override
        public void onAdClicked() {
          defaultChannel.invokeMethod("Interstitial_onAdClicked", null);
        }

        @Override
        public void onAdImpression() {
          defaultChannel.invokeMethod("Interstitial_onAdImpression", null);
        }

        @Override
        public void onAdClosed() {
          defaultChannel.invokeMethod("Interstitial_onAdClosed", null);
        }

        @Override
        public void onAdFailedToShow() {
          defaultChannel.invokeMethod("Interstitial_onAdFailedToShow", null);
        }
      });

      mInterstitialAds.put(adUnitId, interstitialAd);
    }

    return interstitialAd;
  }

  private RewardedAd retrieveRewardedAd(String adUnitId) {
    RewardedAd rewardedAd = mRewardedAds.get(adUnitId);
    if (rewardedAd == null) {
      rewardedAd = new RewardedAd(getCurrentActivity(), adUnitId);

      rewardedAd.setRewardedAdListener(new RewardedAd.RewardedAdListener() {
        @Override
        public void onAdLoaded() {
          defaultChannel.invokeMethod("RewardedAd_onAdLoaded", null);
        }

        @Override
        public void onAdError(int errorCode) {
          Map<String, Object> params = new HashMap<>();
          params.put("error_code", errorCode);
          defaultChannel.invokeMethod("RewardedAd_onAdError", params);
        }

        @Override
        public void onAdClicked() {
          defaultChannel.invokeMethod("RewardedAd_onAdClicked", null);
        }

        @Override
        public void onAdImpression() {
          defaultChannel.invokeMethod("RewardedAd_onAdImpression", null);
        }

        @Override
        public void onAdClosed() {
          defaultChannel.invokeMethod("RewardedAd_onAdClosed", null);
        }

        @Override
        public void onAdRewarded() {
          defaultChannel.invokeMethod("RewardedAd_onAdRewarded", null);
        }

        @Override
        public void onAdFailedToShow() {
          defaultChannel.invokeMethod("RewardedAd_onAdFailedToShow", null);
        }
      });

      mRewardedAds.put(adUnitId, rewardedAd);
    }

    return rewardedAd;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    defaultChannel.setMethodCallHandler(null);
    context = null;
  }

  private Activity getCurrentActivity() {
    return (lastActivityPluginBinding != null) ? lastActivityPluginBinding.getActivity() : null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    lastActivityPluginBinding = binding;
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }
}