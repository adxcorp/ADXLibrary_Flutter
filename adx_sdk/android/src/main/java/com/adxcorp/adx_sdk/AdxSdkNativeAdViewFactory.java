package com.adxcorp.adx_sdk;

import android.content.Context;
import android.util.Log;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class AdxSdkNativeAdViewFactory extends PlatformViewFactory {
  private static final String TAG = "AdxFlutter";
  private final BinaryMessenger messenger;

  public AdxSdkNativeAdViewFactory(BinaryMessenger messenger) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
  }

  @Override
  public PlatformView create(Context context, int viewId, Object args) {
    String adUnitId = null;
    if (args instanceof Map) {
      Object value = ((Map<?, ?>) args).get("ad_unit_id");
      if (value instanceof String) {
        adUnitId = (String) value;
      }
    }

    if (adUnitId == null || adUnitId.isEmpty()) {
      Log.w(TAG, "AdUnitID cannot be empty for native ad view.");
    }

    return new AdxSdkNativeAdView(context, messenger, viewId, adUnitId);
  }
}
