#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint adx_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'adx_sdk'
  s.version          = '2.8.5'
  s.summary          = 'Adx Ads plugin for Flutter'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://www.adxcorp.kr'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chiung Choi' => 'god@adxcorp.kr' }
#   s.source           = { :path => '.' }
  s.source = { :git => 'https://github.com/adxcorp/AdxLibrary_iOS_Release.git', :tag => s.version.to_s }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.vendored_frameworks = "frameworks/*.xcframework"
  s.platform = :ios, '13.0'
  s.static_framework = true

  s.frameworks = [
                      'Accelerate',
                      'AdSupport',
                      'AudioToolbox',
                      'AVFoundation',
                      'CFNetwork',
                      'CoreGraphics',
                      'CoreMotion',
                      'CoreMedia',
                      'CoreTelephony',
                      'Foundation',
                      'GLKit',
                      'MobileCoreServices',
                      'MediaPlayer',
                      'QuartzCore',
                      'StoreKit',
                      'SystemConfiguration',
                      'UIKit',
                      'VideoToolbox',
                      'WebKit'
                   ]

  s.dependency 'Google-Mobile-Ads-SDK', '12.14.0'
  s.dependency 'AppLovinSDK', '13.5.1'
  s.dependency 'AdPieSDK', '1.6.16'
  s.dependency 'FBAudienceNetwork','6.20.1'
  s.dependency 'Ads-Global', '7.9.0.8'
  s.dependency 'UnityAds', '4.17.0'
  s.dependency 'MolocoSDKiOS', '4.4.1'
  s.dependency 'Fyber_Marketplace_SDK', '8.4.5'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
        'DEFINES_MODULE' => 'YES',
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
        'ENABLE_BITCODE' => 'NO',
        'OTHER_LDFLAGS' => '-ObjC'
  }
end
