import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxInterstitialAd extends StatefulWidget {
  const AdxInterstitialAd({super.key});
  @override
  State<StatefulWidget> createState() {
    return _AdxInterstitialAd();
  }
}

class _AdxInterstitialAd extends State<AdxInterstitialAd>{

  String adUnitId = Platform.isAndroid ? "61ee2e3fcb8c67000100002e" : "6200fef52a918d0001000007";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interstitial Ad'),
      ),
      body: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  AdxSdk.setInterstitialListener(InterstitialAdListener(
                      onAdLoaded: (){
                        debugPrint("AdxSample InterstitialAd - onAdLoaded");
                      },
                      onAdError: (int errorCode){
                        debugPrint("AdxSample InterstitialAd - onAdError : $errorCode");
                      },
                      onAdImpression: (){
                        debugPrint("AdxSample InterstitialAd - onAdImpression");
                      },
                      onAdClicked: (){
                        debugPrint("AdxSample InterstitialAd - onAdClicked");
                      },
                      onAdClosed: (){
                        debugPrint("AdxSample InterstitialAd - onAdClosed");
                      },
                      onAdFailedToShow: (){
                        debugPrint("AdxSample InterstitialAd - onAdFailedToShow");
                      })
                  );

                  AdxSdk.loadInterstitial(adUnitId);
                },
                child: const Text('Load'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  bool isLoaded = (await AdxSdk.isInterstitialLoaded(adUnitId))!;
                  if (isLoaded) {
                    AdxSdk.showInterstitial(adUnitId);
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

    AdxSdk.destroyInterstitial(adUnitId);
  }
}