import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'adx_sdk_platform_interface.dart';

/// An implementation of [AdxSdkPlatform] that uses method channels.
class MethodChannelAdxSdk extends AdxSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('adx_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
