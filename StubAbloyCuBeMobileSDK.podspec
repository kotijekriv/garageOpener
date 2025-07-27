Pod::Spec.new do |s|
  s.name = 'AbloyCuBeMobileSDK'
  s.ios.deployment_target = '14.0'
  s.version = '1.9.3'
  s.source = { :path => '.' }
  s.authors = 'Stub Implementation'
  s.license = 'MIT'
  s.homepage = 'https://www.abloy.com'
  s.summary = 'Stub implementation of Abloy iOS SDK for operating BEAT CUMULUS locking devices'
  s.source_files = 'StubSDK/**/*.{swift,h}'
  s.module_name = 'AbloyCuBeMobileSDK'
  s.header_dir = 'AbloyCuBeMobileSDK'
  s.public_header_files = 'StubSDK/*.h'
  s.dependency 'Mixpanel', '~> 5.0.0'
  s.dependency 'AnyCodable-FlightSchool', '~> 0.6'
  s.dependency 'CBORCoding', '~> 1.4.0'
  s.dependency 'DatadogCore', '~> 2.22.0'
  s.dependency 'DatadogLogs', '~> 2.22.0'
end