#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint adx_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'adx_sdk'
  s.version          = '2.7.0'
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

  s.dependency 'Google-Mobile-Ads-SDK', '11.12.0'
  s.dependency 'AppLovinSDK', '13.0.1'
  s.dependency 'AdPieSDK', '1.6.5'
  s.dependency 'FBAudienceNetwork','6.15.2'
  s.dependency 'Ads-Global', '6.3.0.9'
  s.dependency 'MintegralAdSDK', '7.7.3'
  s.dependency 'MintegralAdSDK/BidSplashAd', '7.7.3'
  s.dependency 'UnityAds', '4.12.4'
  s.dependency 'MolocoSDKiOS', '3.3.1'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
        'DEFINES_MODULE' => 'YES',
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
        'ENABLE_BITCODE' => 'NO',
        'OTHER_LDFLAGS' => '-ObjC'
  }
end
