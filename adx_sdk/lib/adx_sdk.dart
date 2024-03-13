
import 'adx_sdk_platform_interface.dart';

class AdxSdk {
  Future<String?> getPlatformVersion() {
    return AdxSdkPlatform.instance.getPlatformVersion();
  }
}
