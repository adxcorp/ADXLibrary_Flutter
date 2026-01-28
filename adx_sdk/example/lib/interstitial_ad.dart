import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxInterstitialAd extends StatefulWidget {
  const AdxInterstitialAd({super.key});

  @override
  State<StatefulWidget> createState() => _AdxInterstitialAdState();
}

class _AdxInterstitialAdState extends State<AdxInterstitialAd> {
  final String _adUnitId = Platform.isAndroid 
      ? "61ee2e3fcb8c67000100002e" 
      : "6200fef52a918d0001000007";

  @override
  void initState() {
    super.initState();
    _setupAdListener();
  }

  void _setupAdListener() {
    AdxSdk.setInterstitialListener(InterstitialAdListener(
      onAdLoaded: () => debugPrint("AdxSample InterstitialAd - onAdLoaded"),
      onAdError: (errorCode) => debugPrint("AdxSample InterstitialAd - onAdError : $errorCode"),
      onAdImpression: () => debugPrint("AdxSample InterstitialAd - onAdImpression"),
      onAdClicked: () => debugPrint("AdxSample InterstitialAd - onAdClicked"),
      onAdClosed: () => debugPrint("AdxSample InterstitialAd - onAdClosed"),
      onAdFailedToShow: () => debugPrint("AdxSample InterstitialAd - onAdFailedToShow"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interstitial Ad')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => AdxSdk.loadInterstitial(_adUnitId),
              child: const Text('Load'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if ((await AdxSdk.isInterstitialLoaded(_adUnitId)) == true) {
                  AdxSdk.showInterstitial(_adUnitId);
                }
              },
              child: const Text('Show'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    AdxSdk.destroyInterstitial(_adUnitId);
    super.dispose();
  }
}