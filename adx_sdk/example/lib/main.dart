import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'banner_ad.dart';
import 'interstitial_ad.dart';
import 'rewarded_ad.dart';
import 'native_ad.dart';

String appId = Platform.isAndroid ? "61ee18cecb8c670001000023" : "6200fea42a918d0001000001";
String maxUnitId = Platform.isAndroid ? "29bb8c3647d905ad" : "48decfe1e3ed88a8";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeAdxPlugin();
  runApp(const MyApp());
}

Future<void> initializeAdxPlugin() async {

  if (Platform.isIOS) {
    /// Do not call the method below if calling 'AdxSdk.initialize()' method with 'gdprTypePopupLocation' or 'gdprTypePopupDebug'
    await requestTrackingAuthorization();
  }

  AdxInitResult adxInitResult = await AdxSdk.initialize(
                                    appId,
                                    AdxCommon.gdprTypeDirectNotRequired,
                                    []);

  bool result = adxInitResult.result;
  int consentState = adxInitResult.consent;
  debugPrint("ADX Init result : $result, consentState : $consentState");
}

Future<void> requestTrackingAuthorization() async {
  final TrackingStatus status =
  await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    final TrackingStatus status =
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
  final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
  debugPrint("UUID: $uuid");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AD(X) Flutter Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'ADX Flutter Sample Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {

    final List<String> adList = <String>[
      'Banner Ad',
      'Interstitial Ad',
      'Rewarded Ad',
      'Native Ad With AppLovin MAX'
    ];

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: ListView.separated(
        itemCount: adList.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(adList[index], textAlign: TextAlign.center),
            onTap: () {
              switch(index) {
                case 0:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdxBanner()),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdxInterstitialAd()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdxRewardedAd()),
                  );
                  break;
                default:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NativeAdView(adUnitId: maxUnitId)),
                  );
                  break;
              }
            },
          );
        }, separatorBuilder: (BuildContext context, int index) { return const Divider(thickness: 0,); },
      )// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
