# Define debug and release configurations
project 'GarageOpenerDemo', {
  'Debug' => :debug,
  'Release' => :release,
}

# Set platform to iOS
platform :ios, '14.0'

# Add release and debug frameworks
target 'GarageOpenerDemo' do
  use_frameworks!
  
  # Path to the Abloy Mobile SDK which is in the parent directory
  sdk_path = '../abloy-mobile-sdk-ios-2.1.0'
  
  # Add the Abloy SDK with configuration-specific variants
  pod 'AbloyCuBeMobileSDK-Debug', :configuration => ['Debug'], :path => sdk_path
  pod 'AbloyCuBeMobileSDK-Release', :configuration => ['Release'], :path => sdk_path
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["BUILD_LIBRARY_FOR_DISTRIBUTION"] = "YES"
  end
end