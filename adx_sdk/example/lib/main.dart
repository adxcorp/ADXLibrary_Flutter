import 'adx_native_ad.dart';
import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'banner_ad.dart';
import 'interstitial_ad.dart';
import 'rewarded_ad.dart';
import 'native_ad.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeAdxPlugin();
  runApp(const MyApp());
}

Future<void> initializeAdxPlugin() async {
  if (Platform.isIOS) {
    await requestTrackingAuthorization();
  }

  String appId = Platform.isAndroid 
      ? "61ee18cecb8c670001000023" 
      : "61ee3aafcb8c670001000034";

  AdxInitResult result = await AdxSdk.initialize(
    appId, 
    AdxCommon.gdprTypeDirectNotRequired, 
    []
  );

  debugPrint("ADX Init result : ${result.result}, consentState : ${result.consent}");
}

Future<void> requestTrackingAuthorization() async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
  final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
  debugPrint("UUID: $uuid");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AD(X) Flutter Sample',
      theme: ThemeData(primarySwatch: Colors.blue),
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
  final Map<String, WidgetBuilder> _demos = {
    'Banner Ad': (context) => const AdxBanner(),
    'Interstitial Ad': (context) => const AdxInterstitialAd(),
    'Rewarded Ad': (context) => const AdxRewardedAd(),
    'Native Ad': (context) => const AdxTestNativeAdView(adUnitId: '61ee2ea2cb8c670001000030'), // ios : 61ee3ae4cb8c670001000038
    'Native Ad With AppLovin MAX': (context) => NativeAdView(
        adUnitId: Platform.isAndroid ? "29bb8c3647d905ad" : "48decfe1e3ed88a8"
    ),
  };

  @override
  Widget build(BuildContext context) {
    final demoKeys = _demos.keys.toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.separated(
        itemCount: _demos.length,
        itemBuilder: (context, index) {
          final title = demoKeys[index];
          return ListTile(
            title: Text(title, textAlign: TextAlign.center),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: _demos[title]!)
              );
            },
          );
        },
        separatorBuilder: (context, index) => const Divider(thickness: 0),
      ),
    );
  }
}
