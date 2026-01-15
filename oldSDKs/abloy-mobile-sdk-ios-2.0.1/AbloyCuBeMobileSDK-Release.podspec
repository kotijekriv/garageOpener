Pod::Spec.new do |s|
  s.name = 'AbloyCuBeMobileSDK-Release'
  s.ios.deployment_target = '14.0'
  s.version = '2.0.1'
  s.source = { :path => '.' }
  s.authors = 'Abloy Oy'
  s.license = 'Proprietary'
  s.homepage = 'https://git.tools.dev.assaabloyglobalsolutions.net/abloy/platform/mobile/beat-app-ios'
  s.summary = 'Abloy iOS SDK for operating BEAT CUMULUS locking devices'
  s.dependency 'Mixpanel', '~> 5.0.0'
  s.dependency 'AnyCodable-FlightSchool', '~> 0.6'
  s.dependency 'CBORCoding', '~> 1.4.0'
  s.dependency 'DatadogCore', '~> 2.29.0'
  s.dependency 'DatadogLogs', '~> 2.29.0'
  s.vendored_frameworks = 'AbloyCuBeMobileSDK.xcframework', 'ThingRPC.xcframework', 'MobileConnector.xcframework', 'Release/SeosMobileKeysSDK.xcframework'
end
