package com.adxcorp.adx_sdk;

import android.content.Context;
import android.graphics.Color;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.adxcorp.ads.nativeads.AdxNativeAdFactory;
import com.adxcorp.ads.nativeads.AdxViewBinder;
import com.adxcorp.ads.nativeads.NativeAd;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformView;

public class AdxSdkNativeAdView implements PlatformView, MethodCallHandler, AdxNativeAdFactory.NativeAdListener {
  private static final String TAG = "AdxFlutter";

  private final Context context;
  private final String adUnitId;
  private final MethodChannel channel;
  private final FrameLayout platformView;

  private View nativeAdView;
  private boolean destroyed = false;

  private final NativeAd.NativeEventListener nativeEventListener =
      new NativeAd.NativeEventListener() {
        @Override
        public void onImpression(View view) {
          Log.d(TAG, "NativeAd impression");
        }

        @Override
        public void onClick(View view) {
          Log.d(TAG, "NativeAd click");
        }
      };

  public AdxSdkNativeAdView(Context context, BinaryMessenger messenger, int viewId, String adUnitId) {
    this.context = context;
    this.adUnitId = adUnitId;
    this.platformView = new FrameLayout(context);
    this.platformView.setLayoutParams(
        new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT));

    String channelName = "adx_sdk/native_ad_view_" + viewId;
    this.channel = new MethodChannel(messenger, channelName);
    this.channel.setMethodCallHandler(this);

    ensureFactoryInitialized();
    registerViewBinder();
    AdxNativeAdFactory.addListener(this);
  }

  @Override
  public View getView() {
    return platformView;
  }

  @Override
  public void dispose() {
    destroyNativeAd();
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "loadNativeAd":
        loadNativeAd();
        result.success(null);
        break;
      case "destroyNativeAd":
        destroyNativeAd();
        result.success(null);
        break;
      case "addTitleTextView":
        configureView(
            findAssetView(R.id.adx_native_ad_title),
            call,
            true);
        result.success(null);
        break;
      case "addMainTextView":
        configureView(
            findAssetView(R.id.adx_native_ad_body),
            call,
            true);
        result.success(null);
        break;
      case "addCTAButtonView":
        configureView(
            findAssetView(R.id.adx_native_ad_cta),
            call,
            true);
        result.success(null);
        break;
      case "addIconImageView":
        configureView(
            findAssetView(R.id.adx_native_ad_icon),
            call,
            false);
        result.success(null);
        break;
      case "addMainImageView":
        configureView(
            findAssetView(R.id.adx_native_ad_media),
            call,
            false);
        result.success(null);
        break;
      case "addPrivacyIconImageView":
        configureView(
            findAssetView(R.id.adx_native_ad_adchoice),
            call,
            false);
        result.success(null);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void loadNativeAd() {
    if (TextUtils.isEmpty(adUnitId)) {
      Log.w(TAG, "NativeAd load ignored: adUnitId is empty.");
      return;
    }
    AdxNativeAdFactory.loadAd(adUnitId);
  }

  private void destroyNativeAd() {
    if (destroyed) {
      return;
    }
    destroyed = true;
    AdxNativeAdFactory.removeListener(this);
    platformView.removeAllViews();
    nativeAdView = null;
  }

  @Override
  public void onSuccess(String adUnitId, NativeAd nativeAd) {
    if (destroyed || !TextUtils.equals(this.adUnitId, adUnitId)) {
      return;
    }

    platformView.removeAllViews();

    View view = AdxNativeAdFactory.getNativeAdView(context, adUnitId, platformView, nativeEventListener);
    if (view == null) {
      onFailure(adUnitId);
      return;
    }

    nativeAdView = view;
    if (view.getParent() == null) {
      platformView.addView(view,
          new FrameLayout.LayoutParams(
              FrameLayout.LayoutParams.MATCH_PARENT,
              FrameLayout.LayoutParams.MATCH_PARENT));
    }

    Map<String, Object> args = extractAdData();
    if (args.isEmpty()) {
      Log.w(TAG, "failed to extract ad data.");
      onFailure(adUnitId);
      return;
    }
    args.put("ad_unit_id", adUnitId);
    channel.invokeMethod("NativeAd_onSuccess", args);
  }

  @Override
  public void onFailure(String adUnitId) {
    if (destroyed || !TextUtils.equals(this.adUnitId, adUnitId)) {
      return;
    }
    Map<String, Object> args = new HashMap<>();
    args.put("ad_unit_id", adUnitId);
    channel.invokeMethod("NativeAd_onFailure", args);
  }

  private void ensureFactoryInitialized() {
    if (!AdxNativeAdFactory.isInitialized()) {
      AdxNativeAdFactory.init(context.getApplicationContext());
    }
  }

  private void registerViewBinder() {
    if (TextUtils.isEmpty(adUnitId)) {
      return;
    }

    AdxViewBinder binder =
        new AdxViewBinder.Builder(R.layout.adx_native_ad_view)
            .titleId(R.id.adx_native_ad_title)
            .textId(R.id.adx_native_ad_body)
            .callToActionId(R.id.adx_native_ad_cta)
            .iconImageId(R.id.adx_native_ad_icon)
            .mediaViewContainerId(R.id.adx_native_ad_media)
            .adChoiceContainerId(R.id.adx_native_ad_adchoice)
            .advertiserNameId(R.id.adx_native_ad_advertiser)
            .build();

    AdxNativeAdFactory.setAdxViewBinder(adUnitId, binder);
  }

  private View findAssetView(int id) {
    if (nativeAdView == null) {
      return null;
    }
    return nativeAdView.findViewById(id);
  }

  private void configureView(View view, MethodCall call, boolean transparent) {
    if (view == null || nativeAdView == null) {
      return;
    }

    ViewParent parent = view.getParent();
    if (parent instanceof ViewGroup && parent != nativeAdView) {
      ((ViewGroup) parent).removeView(view);
    }
    if (view.getParent() == null && nativeAdView instanceof ViewGroup) {
      ((ViewGroup) nativeAdView).addView(view);
    }

    FrameLayout.LayoutParams params = buildLayoutParams(call);
    view.setLayoutParams(params);
    view.setVisibility(View.VISIBLE);

    if (transparent) {
      makeTransparent(view);
    }
  }

  private FrameLayout.LayoutParams buildLayoutParams(MethodCall call) {
    int x = getIntArg(call, "x");
    int y = getIntArg(call, "y");
    int width = getIntArg(call, "width");
    int height = getIntArg(call, "height");
    FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(width, height);
    params.leftMargin = x;
    params.topMargin = y;
    return params;
  }

  private int getIntArg(MethodCall call, String key) {
    Object value = call.argument(key);
    if (value instanceof Number) {
      return ((Number) value).intValue();
    }
    return 0;
  }

  private void makeTransparent(View view) {
    view.setBackgroundColor(Color.TRANSPARENT);
    if (view instanceof TextView) {
      ((TextView) view).setTextColor(Color.TRANSPARENT);
    } else if (view instanceof Button) {
      ((Button) view).setTextColor(Color.TRANSPARENT);
      view.setBackgroundColor(Color.TRANSPARENT);
    }
  }

  private Map<String, Object> extractAdData() {
    Map<String, Object> args = new HashMap<>();
    if (nativeAdView == null) {
      return args;
    }

    TextView title = nativeAdView.findViewById(R.id.adx_native_ad_title);
    if (title != null && !TextUtils.isEmpty(title.getText())) {
      args.put("headline", title.getText().toString());
    }

    TextView body = nativeAdView.findViewById(R.id.adx_native_ad_body);
    if (body != null && !TextUtils.isEmpty(body.getText())) {
      args.put("body", body.getText().toString());
    }

    View ctaView = nativeAdView.findViewById(R.id.adx_native_ad_cta);
    if (ctaView instanceof TextView) {
      CharSequence text = ((TextView) ctaView).getText();
      if (!TextUtils.isEmpty(text)) {
        args.put("callToAction", text.toString());
      }
    }

    return args;
  }
}
