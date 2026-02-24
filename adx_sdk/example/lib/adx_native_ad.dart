import 'package:adx_sdk/adx_sdk.dart';
import 'package:flutter/material.dart';

class AdxTestNativeAdView extends StatefulWidget {
  const AdxTestNativeAdView({super.key, required this.adUnitId});
  final String adUnitId;

  @override
  State createState() => _AdxTestNativeAdViewState();
}

class _AdxTestNativeAdViewState extends State<AdxTestNativeAdView> {
  static const double _mediaViewAspectRatio = 16 / 9;
  final AdxNativeAdController _nativeAdViewController = AdxNativeAdController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADX NativeAd')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Dummy content (Top)
              ...List.generate(2, (index) => _buildDummyItem(index)),

              // Native Ad View
              Container(
                margin: const EdgeInsets.all(8.0),
                height: 330,
                child: AdxNativeAdView(
                  adUnitId: widget.adUnitId,
                  controller: _nativeAdViewController,
                  listener: AdxNativeAdListener(
                    onSuccess: (id) => debugPrint("AdxSample NativeAd - onSuccess, AdUnitId : $id"),
                    onFailure: (id) => debugPrint("AdxSample NativeAd - onFailure, AdUnitId : $id"),
                  ),
                  child: _buildNativeAdContent(),
                ),
              ),

              const SizedBox(height: 10),

              // Load Button
              ElevatedButton(
                onPressed: () => _nativeAdViewController.loadNativeAd(),
                child: const Text('Load ADX Native Ad'),
              ),

              // Dummy content (Bottom)
              ...List.generate(15, (index) => _buildDummyItem(index + 5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDummyItem(int index) {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(8),
      color: Colors.grey[300],
      child: Center(child: Text("Dummy Item $index")),
    );
  }

  Widget _buildNativeAdContent() {
    return Container(
      color: const Color(0xffefefef),
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ad Badge
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(left: 5, top: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Ad",
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Header: Icon + Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    margin: const EdgeInsets.only(right: 10.0),
                    padding: const EdgeInsets.all(4.0),
                    child: const AdxNativeAdIconView(width: 48, height: 48),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdxNativeAdTitleTextView(
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Body Text
              const Row(
                children: [
                  Flexible(
                    child: AdxNativeAdMainTextView(
                      style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Media View
              const Expanded(
                child: AspectRatio(
                  aspectRatio: _mediaViewAspectRatio,
                  child: AdxNativeAdMainImageView(),
                ),
              ),

              const SizedBox(height: 8),

              // Call To Action Button
              const SizedBox(
                width: double.infinity,
                child: AdxNativeAdCallToActionButtonView(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
                    textStyle: WidgetStatePropertyAll<TextStyle>(
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Privacy Icon (AdChoices)
          const Positioned(
            right: 5,
            top: 5,
            child: AdxNativeAdPrivacyIconImageView(width: 20, height: 20),
          ),
        ],
      ),
    );
  }
}
