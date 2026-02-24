import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String _viewType = "adx_sdk/native_ad_view";

/// A scope widget that allows child widgets to access the parent [_AdxNativeAdViewState].
class _AdxNativeAdScope extends InheritedWidget {
  const _AdxNativeAdScope({
    required this.state,
    required super.child,
  });

  final _AdxNativeAdViewState state;

  static _AdxNativeAdViewState of(BuildContext ctx) {
    return ctx.dependOnInheritedWidgetOfExactType<_AdxNativeAdScope>()!.state;
  }

  @override
  bool updateShouldNotify(_) => true;
}

/// Controller used to trigger native ad loading from Flutter to the platform side.
class AdxNativeAdController extends ChangeNotifier {
  void loadNativeAd() {
    notifyListeners();
  }
}

/// Listener for native ad events. Provides callbacks for success and failure.
class AdxNativeAdListener {
  final void Function(String adUnitId) onSuccess;
  final void Function(String adUnitId) onFailure;
  
  AdxNativeAdListener({
    required this.onSuccess,
    required this.onFailure
  });
}

/// Main widget for displaying native ads and interacting with the platform view.
/// This widget creates a PlatformView (AndroidView or UiKitView) to host the native ad.
class AdxNativeAdView extends StatefulWidget {
  final String adUnitId;
  final double width;
  final double height;
  final Widget child;
  final AdxNativeAdController? controller;
  final AdxNativeAdListener? listener;

  const AdxNativeAdView({
    super.key,
    required this.adUnitId,
    this.width = double.infinity,
    this.height = double.infinity,
    this.listener,
    required this.controller,
    required this.child,
  });

  @override
  State<AdxNativeAdView> createState() => _AdxNativeAdViewState();
}

class _AdxNativeAdViewState extends State<AdxNativeAdView> {
  final GlobalKey _nativeAdViewKey = GlobalKey();

  final Map<String, GlobalKey> _assetKeys = {
    'title_text': GlobalKey(),
    'main_text': GlobalKey(),
    'cta_button': GlobalKey(),
    'icon_image': GlobalKey(),
    'main_image': GlobalKey(),
    'privacy_icon_image': GlobalKey(),
  };
  
  Map<String, dynamic> _adData = {};
  Map<String, dynamic> get adData => _adData;

  final Map<String, String> _assetMethods = {
    'title_text': 'addTitleTextView',
    'main_text': 'addMainTextView',
    'icon_image': 'addIconImageView',
    'cta_button': 'addCTAButtonView',
    'main_image': 'addMainImageView',
    'privacy_icon_image': 'addPrivacyIconImageView',
  };

  MethodChannel? _methodChannel;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _methodChannel?.invokeMethod("destroyNativeAd");
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdxNativeAdScope(
      state: this,
      child: SizedBox(
        key: _nativeAdViewKey,
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            widget.child,
            if (defaultTargetPlatform == TargetPlatform.android)
              AndroidView(
                viewType: _viewType,
                creationParams: _createParams(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onAdxNativeAdViewCreated,
              ),
            if (defaultTargetPlatform == TargetPlatform.iOS)
              UiKitView(
                viewType: _viewType,
                creationParams: _createParams(),
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: _onAdxNativeAdViewCreated,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _createParams() {
    return {
      "ad_unit_id": widget.adUnitId,
    };
  }

  void _handleControllerChanged() {
    setState(() { _adData = {}; });
    _methodChannel?.invokeMethod("loadNativeAd");
  }

  void _onAdxNativeAdViewCreated(int id) {
    _methodChannel = MethodChannel('${_viewType}_$id')
      ..setMethodCallHandler(_handleNativeMethodCall);
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    try {
      final String method = call.method;
      final Map<dynamic, dynamic>? arguments = call.arguments;

      if (method == "NativeAd_onSuccess") {
        setState(() {
          if (arguments != null) {
            _adData = Map<String, dynamic>.from(arguments);
          }
        });
        await _updateAllAssetViews();
        widget.listener?.onSuccess(widget.adUnitId);
      } else if (method == "NativeAd_onFailure") {
        setState(() { _adData = {}; });
        widget.listener?.onFailure(widget.adUnitId);
      } else {
        throw MissingPluginException('No handler for method $method');
      }
    } catch (e) {
      debugPrint('Error handling native method call ${call.method} with arguments ${call.arguments}: $e');
    }
  }

  Future _invokeAssetViewMethod(GlobalKey? key, String method) async {
    if (key == null) return;
    
    Rect rect = _getViewSize(key, _nativeAdViewKey);
    if (rect.isEmpty) return;

    Map<String, dynamic> params;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      /// iOS coordinates are in points, matching Flutter's logical pixels.
      params = {
        'x': rect.left,
        'y': rect.top,
        'width': rect.width,
        'height': rect.height,
      };
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      /// Android requires physical pixels, so multiply by devicePixelRatio.
      double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      params = {
        'x': (rect.left * devicePixelRatio).round(),
        'y': (rect.top * devicePixelRatio).round(),
        'width': (rect.width * devicePixelRatio).round(),
        'height': (rect.height * devicePixelRatio).round(),
      };
    } else {
      return;
    }

    return _methodChannel?.invokeMethod(method, params);
  }

  Future _updateAllAssetViews() async {
    return Future.wait(
      _assetMethods.entries.map(
            (e) => _updateAssetView(_assetKeys[e.key], e.value),
      ),
    );
  }

  Future _updateAssetView(GlobalKey? key, String method) async {
    return _invokeAssetViewMethod(key, method);
  }

  Rect _getViewSize(GlobalKey key, GlobalKey parentKey) {
    RenderBox? renderedObject = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderedObject == null) return Rect.zero;
    Offset globalPosition = renderedObject.localToGlobal(Offset.zero);
    final parentBox = parentKey.currentContext?.findRenderObject();
    if (parentBox is! RenderBox) return Rect.zero;
    Offset relativePosition = parentBox.globalToLocal(globalPosition);
    return relativePosition & renderedObject.size;
  }
}

/// Placeholder widget for the ad title; reports position and size to the native platform.
class AdxNativeAdTitleTextView extends StatelessWidget {
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;

  const AdxNativeAdTitleTextView({
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _AdxNativeAdScope.of(context);
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scope._assetKeys['title_text'] == null) return;
          scope._updateAssetView(scope._assetKeys['title_text'], scope._assetMethods['title_text']!);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          scope.adData['headline'] ?? '',
          key: scope._assetKeys['title_text'],
          style: style,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

/// Placeholder widget for the ad body; reports position and size to the native platform.
class AdxNativeAdMainTextView extends StatelessWidget {
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;

  const AdxNativeAdMainTextView({
    super.key,
    this.style,
    this.textAlign,
    this.softWrap,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _AdxNativeAdScope.of(context);
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scope._assetKeys['main_text'] == null) return;
          scope._updateAssetView(scope._assetKeys['main_text'], scope._assetMethods['main_text']!);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Text(
          scope.adData['body'] ?? '',
          key: scope._assetKeys['main_text'],
          style: style,
          textAlign: textAlign,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        ),
      ),
    );
  }
}

/// Placeholder widget for the ad icon; reports position and size to the native platform.
class AdxNativeAdIconView extends StatelessWidget {
  final double? width;
  final double? height;

  const AdxNativeAdIconView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _AdxNativeAdScope.of(context);

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scope._updateAssetView(scope._assetKeys['icon_image'], scope._assetMethods['icon_image']!);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: scope._assetKeys['icon_image'],
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

/// Placeholder widget for the CTA button; reports position and size to the native platform.
class AdxNativeAdCallToActionButtonView extends StatelessWidget {
  final ButtonStyle? style;

  const AdxNativeAdCallToActionButtonView({
    super.key,
    this.style
  });

  @override
  Widget build(BuildContext context) {
    final scope = _AdxNativeAdScope.of(context);
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scope._assetKeys['cta_button'] == null) return;
          scope._updateAssetView(scope._assetKeys['cta_button'], scope._assetMethods['cta_button']!);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: ElevatedButton(
          key: scope._assetKeys['cta_button'],
          style: style,
          onPressed: () {},
          child: Text(
            scope.adData['callToAction'] ?? ''
          ),
        ),
      ),
    );
  }
}

/// Placeholder widget for media content (image/video); reports position and size to the native platform.
class AdxNativeAdMainImageView extends StatelessWidget {
  final double? width;
  final double? height;

  const AdxNativeAdMainImageView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _AdxNativeAdScope.of(context);

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scope._updateAssetView(scope._assetKeys['main_image'], scope._assetMethods['main_image']!);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: scope._assetKeys['main_image'],
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}

/// Placeholder widget for privacy information icon; reports position and size to the native platform.
class AdxNativeAdPrivacyIconImageView extends StatelessWidget {
  final double? width;
  final double? height;

  const AdxNativeAdPrivacyIconImageView({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final scope = _AdxNativeAdScope.of(context);

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scope._updateAssetView(scope._assetKeys['privacy_icon_image'], scope._assetMethods['privacy_icon_image']!);
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Container(
          key: scope._assetKeys['privacy_icon_image'],
          width: width,
          height: height,
          color: Colors.transparent,
        ),
      ),
    );
  }
}