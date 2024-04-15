import 'package:flutter/material.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'banner_ad.dart';
import 'interstitial_ad.dart';
import 'rewarded_ad.dart';

String appId = Platform.isAndroid ? "61ee18cecb8c670001000023" : "6200fea42a918d0001000001";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    initializeAdxPlugin();
  } else if (Platform.isIOS) {
    initAttPlugin();
  }

  runApp(const MyApp());
}

Future<void> initializeAdxPlugin() async {
  AdxInitResult adxInitResult = await AdxSdk.initialize(appId, AdxCommon.gdprTypeDirectNotRequired, []);
  print("adxInitResult : ${adxInitResult.result}, ${adxInitResult.consent}");
}

Future<void> initAttPlugin() async {
  final TrackingStatus status =
  await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    final TrackingStatus status =
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
  print("UUID: $uuid");

  initializeAdxPlugin();
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AD(X) Flutter Sample',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'ADX Flutter Sample Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    final List<String> adList = <String>['Banner Ad', 'Interstitial Ad', 'Rewarded Ad'];

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
                    MaterialPageRoute(builder: (context) => AdxBanner()),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdxInterstitialAd()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdxRewardedAd()),
                  );
                  break;
              }
            },
          );
        }, separatorBuilder: (BuildContext context, int index) { return Divider(thickness: 0,); },
      )// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
