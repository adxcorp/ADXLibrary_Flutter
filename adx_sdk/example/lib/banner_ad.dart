import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxBanner extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AdxBanner();
  }
}

class _AdxBanner extends State<AdxBanner> {

  String adUnitId = Platform.isAndroid ? "61ee2b7dcb8c67000100002a" : "6200fee42a918d0001000003";

  @override
  void initState() {
    super.initState();
    AdxSdk.setBannerListener(BannerListener(
        onAdLoaded: (){
          print("AdxSample AdView - onAdLoaded");
        },
        onAdError: (int errorCode) {
          print("AdxSample AdView - onAdError : $errorCode");
        },
        onAdClicked: (){
          print("AdxSample AdView - onAdClicked");
        }));

    AdxSdk.setBannerPosition(adUnitId, AdxCommon.positionBottomCenter);
    AdxSdk.loadBannerAd(adUnitId, AdxCommon.size_320x50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Ad'),
      ),
      body: Container(),
    );
  }

  @override
  void dispose() {
    super.dispose();

    AdxSdk.destroyBannerAd(adUnitId);
  }
}