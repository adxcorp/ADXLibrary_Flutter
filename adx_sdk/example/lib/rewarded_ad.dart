import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxRewardedAd extends StatefulWidget {
  const AdxRewardedAd({super.key});

  @override
  State<StatefulWidget> createState() => _AdxRewardedAdState();
}

class _AdxRewardedAdState extends State<AdxRewardedAd> {
  final String _adUnitId = Platform.isAndroid 
      ? "61ee2e91cb8c67000100002f" 
      : "6200ff0c2a918d000100000d";

  @override
  void initState() {
    super.initState();
    _setupAdListener();
  }

  void _setupAdListener() {
    AdxSdk.setRewardedAdListener(RewardedAdListener(
      onAdLoaded: () => debugPrint("AdxSample RewardedAd - onAdLoaded"),
      onAdError: (errorCode) => debugPrint("AdxSample RewardedAd - onAdError : $errorCode"),
      onAdImpression: () => debugPrint("AdxSample RewardedAd - onAdImpression"),
      onAdClicked: () => debugPrint("AdxSample RewardedAd - onAdClicked"),
      onAdRewarded: () => debugPrint("AdxSample RewardedAd - onAdRewarded"),
      onAdClosed: () => debugPrint("AdxSample RewardedAd - onAdClosed"),
      onAdFailedToShow: () => debugPrint("AdxSample RewardedAd - onAdFailedToShow"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewarded Ad')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => AdxSdk.loadRewardedAd(_adUnitId),
              child: const Text('Load'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if ((await AdxSdk.isRewardedAdLoaded(_adUnitId)) == true) {
                  AdxSdk.showRewardedAd(_adUnitId);
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
    AdxSdk.destroyRewardedAd(_adUnitId);
    super.dispose();
  }
}