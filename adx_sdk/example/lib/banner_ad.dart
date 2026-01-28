import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxBanner extends StatefulWidget {
  const AdxBanner({super.key});

  @override
  State<StatefulWidget> createState() => _AdxBannerState();
}

class _AdxBannerState extends State<AdxBanner> {
  final String _adUnitId = Platform.isAndroid 
      ? "61ee2b7dcb8c67000100002a" 
      : "6200fee42a918d0001000003";

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    AdxSdk.setBannerListener(BannerListener(
      onAdLoaded: () => debugPrint("AdxSample AdView - onAdLoaded"),
      onAdError: (errorCode) => debugPrint("AdxSample AdView - onAdError : $errorCode"),
      onAdClicked: () => debugPrint("AdxSample AdView - onAdClicked"),
    ));

    AdxSdk.setBannerPosition(_adUnitId, AdxCommon.positionBottomCenter);
    AdxSdk.loadBannerAd(_adUnitId, AdxCommon.size_320x50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banner Ad')),
      body: Container(),
    );
  }

  @override
  void dispose() {
    AdxSdk.destroyBannerAd(_adUnitId);
    super.dispose();
  }
}