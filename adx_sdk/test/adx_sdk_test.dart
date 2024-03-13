import 'package:flutter_test/flutter_test.dart';
import 'package:adx_sdk/adx_sdk.dart';
import 'package:adx_sdk/adx_sdk_platform_interface.dart';
import 'package:adx_sdk/adx_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdxSdkPlatform
    with MockPlatformInterfaceMixin
    implements AdxSdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AdxSdkPlatform initialPlatform = AdxSdkPlatform.instance;

  test('$MethodChannelAdxSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdxSdk>());
  });

  test('getPlatformVersion', () async {
    AdxSdk adxSdkPlugin = AdxSdk();
    MockAdxSdkPlatform fakePlatform = MockAdxSdkPlatform();
    AdxSdkPlatform.instance = fakePlatform;

    expect(await adxSdkPlugin.getPlatformVersion(), '42');
  });
}
