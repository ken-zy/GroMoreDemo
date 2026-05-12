Pod::Spec.new do |s|
    s.name             = 'BUMentaCustomAdapter'
    s.version          = '7.00.03'
    s.summary          = 'BUMentaCustomAdapter.podspec.'
    s.description      = 'This is the BUMentaCustomAdapter.podspec. Please proceed to https://www.mentamob.com for more information.'
    s.homepage         = 'https://www.mentamob.com/'
    s.license          = "Custom"
    s.author           = { 'menta' => 'mentasdk.vip@gmail.com' }
    s.source           = { :git => "https://github.com/JiaDingYi/GroMoreDemo.git", :tag => "#{s.version}" }
  
    s.ios.deployment_target = '11.0'
    s.frameworks = 'UIKit', 'MapKit', 'MediaPlayer', 'CoreLocation', 'AdSupport', 'CoreMedia', 'AVFoundation', 'CoreTelephony', 'StoreKit', 'SystemConfiguration', 'MobileCoreServices', 'CoreMotion', 'Accelerate','AudioToolbox','JavaScriptCore','Security','CoreImage','AudioToolbox','ImageIO','QuartzCore','CoreGraphics','CoreText'
    s.libraries = 'c++', 'resolv', 'z', 'sqlite3', 'bz2', 'xml2', 'iconv', 'c++abi'
    s.weak_frameworks = 'WebKit', 'AdSupport'
    s.static_framework = true
  
    s.source_files = 'BUMentaCustomAdapter/**/*'

    s.dependency 'MentaVlionBaseSDK', '~> 7.00.26'
    s.dependency 'MentaUnifiedSDK',   '~> 7.00.26'
    s.dependency 'MentaVlionSDK',     '~> 7.00.26'
    s.dependency 'MentaVlionAdapter', '~> 7.00.26'
    s.dependency 'Ads-CN'
    s.dependency 'Ads-CN/CSJMediation'
  
  end