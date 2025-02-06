import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxRewardedAd extends StatefulWidget {
  const AdxRewardedAd({super.key});
  @override
  State<StatefulWidget> createState() {
    return _AdxRewardedAd();
  }
}

class _AdxRewardedAd extends State<AdxRewardedAd> {

  String adUnitId = Platform.isAndroid ? "61ee2e91cb8c67000100002f" : "6200ff0c2a918d000100000d";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewarded Ad'),
      ),
      body: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  AdxSdk.setRewardedAdListener(RewardedAdListener(
                    onAdLoaded: (){
                      debugPrint("AdxSample RewardedAd - onAdLoaded");
                    }, onAdError: (int errorCode){
                      debugPrint("AdxSample RewardedAd - onAdError : $errorCode");
                    }, onAdImpression: (){
                      debugPrint("AdxSample RewardedAd - onAdImpression");
                    }, onAdClicked: (){
                      debugPrint("AdxSample RewardedAd - onAdClicked");
                    }, onAdRewarded: (){
                      debugPrint("AdxSample RewardedAd - onAdRewarded");
                    }, onAdClosed: (){
                      debugPrint("AdxSample RewardedAd - onAdClosed");
                    }, onAdFailedToShow: (){
                      debugPrint("AdxSample RewardedAd - onAdFailedToShow");
                    }));
                  AdxSdk.loadRewardedAd(adUnitId);
                },
                child: const Text('Load'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  bool isLoaded = (await AdxSdk.isRewardedAdLoaded(adUnitId))!;
                  if (isLoaded) {
                    AdxSdk.showRewardedAd(adUnitId);
                  }
                },
                child: const Text('Show'),
              ),
            ],
          )
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    AdxSdk.destroyRewardedAd(adUnitId);
  }
}