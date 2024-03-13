import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'adx_sdk_method_channel.dart';

abstract class AdxSdkPlatform extends PlatformInterface {
  /// Constructs a AdxSdkPlatform.
  AdxSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdxSdkPlatform _instance = MethodChannelAdxSdk();

  /// The default instance of [AdxSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelAdxSdk].
  static AdxSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdxSdkPlatform] when
  /// they register themselves.
  static set instance(AdxSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
