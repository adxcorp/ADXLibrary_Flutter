import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxRewardedAd extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AdxRewardedAd();
  }
}

class _AdxRewardedAd extends State<AdxRewardedAd> {

  String adUnitId = Platform.isAndroid ? "61ee2e91cb8c67000100002f" : "";

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
                      print("AdxSample RewardedAd - onAdLoaded");
                    }, onAdError: (int errorCode){
                      print("AdxSample RewardedAd - onAdError : $errorCode");
                    }, onAdImpression: (){
                      print("AdxSample RewardedAd - onAdImpression");
                    }, onAdClicked: (){
                      print("AdxSample RewardedAd - onAdClicked");
                    }, onAdRewarded: (){
                      print("AdxSample RewardedAd - onAdRewarded");
                    }, onAdClosed: (){
                      print("AdxSample RewardedAd - onAdClosed");
                    }, onAdFailedToShow: (){
                      print("AdxSample RewardedAd - onAdFailedToShow");
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