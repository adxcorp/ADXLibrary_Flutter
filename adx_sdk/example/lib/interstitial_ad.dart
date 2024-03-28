import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;

class AdxInterstitialAd extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AdxInterstitialAd();
  }
}

class _AdxInterstitialAd extends State<AdxInterstitialAd>{

  String adUnitId = Platform.isAndroid ? "61ee2e3fcb8c67000100002e" : "";

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
                        print("AdxSample InterstitialAd - onAdLoaded");
                      },
                      onAdError: (int errorCode){
                        print("AdxSample InterstitialAd - onAdError : $errorCode");
                      },
                      onAdImpression: (){
                        print("AdxSample InterstitialAd - onAdImpression");
                      },
                      onAdClicked: (){
                        print("AdxSample InterstitialAd - onAdClicked");
                      },
                      onAdClosed: (){
                        print("AdxSample InterstitialAd - onAdClosed");
                      },
                      onAdFailedToShow: (){
                        print("AdxSample InterstitialAd - onAdFailedToShow");
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