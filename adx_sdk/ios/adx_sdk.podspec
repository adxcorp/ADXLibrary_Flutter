#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint adx_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'adx_sdk'
  s.version          = '2.9.0'
  s.summary          = 'ADXLibrary for Flutter'
  s.description      = 'ADXLibrary for Flutter'
  s.homepage         = 'https://www.adxcorp.kr'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chiung Choi' => 'god@adxcorp.kr' }
  s.source = { :git => 'https://github.com/adxcorp/AdxLibrary_iOS_Release.git', :tag => s.version.to_s }
  # Shares its source with the Swift Package (adx_sdk/Package.swift) so CocoaPods
  # and Swift Package Manager consumers build from the exact same files.
  s.source_files = 'adx_sdk/Sources/adx_sdk/**/*'
  s.public_header_files = 'adx_sdk/Sources/adx_sdk/**/*.h'
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

  s.dependency 'Google-Mobile-Ads-SDK', '13.6.0'
  s.dependency 'AppLovinSDK', '13.6.3'
  s.dependency 'AdPieSDK', '1.7.1'
  s.dependency 'FBAudienceNetwork','6.21.1'
  s.dependency 'Ads-Global', '8.2.0.9'
  s.dependency 'UnityAds', '4.19.0'
  s.dependency 'MolocoSDKiOS', '4.9.0.0'
  s.dependency 'Fyber_Marketplace_SDK', '8.4.7'
  s.dependency 'VungleAds', '7.7.6'
  s.dependency 'MintegralAdSDK', '8.1.5'
  s.dependency 'MintegralAdSDK/BidSplashAd', '8.1.5'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
        'DEFINES_MODULE' => 'YES',
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
        'ENABLE_BITCODE' => 'NO',
        'OTHER_LDFLAGS' => '-ObjC'
  }
end
