#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint adx_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'adx_sdk'
  s.version          = '2.5.4'
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
  s.platform = :ios, '12.0'
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

  s.libraries = 'z', 'sqlite3', 'xml2', 'c++'

  s.dependency 'Google-Mobile-Ads-SDK', '11.2.0'
  s.dependency 'AppLovinSDK', '12.3.0'
  s.dependency 'AdPieSDK', '1.6.0'
  s.dependency 'FBAudienceNetwork','6.15.0'
  s.dependency 'Ads-Global/BUAdSDK_Compatible', '5.8.0.8'
  s.dependency 'MintegralAdSDK', '7.5.9'
  s.dependency 'MintegralAdSDK/BidSplashAd', '7.5.9'
  s.dependency 'Fyber_Marketplace_SDK', '8.2.7'
  s.dependency 'UnityAds', '4.10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
        'DEFINES_MODULE' => 'YES',
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
        'ENABLE_BITCODE' => 'NO',
        'OTHER_LDFLAGS' => '-ObjC'
  }
end
