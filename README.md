# Garage Door Opener Demo

A demo iOS app that demonstrates how to use the Abloy CuBe Mobile SDK v1.9.3 to control garage doors.

## Current Integration Status

The project uses a stub implementation of the Abloy SDK to allow the app to compile and demonstrate the UI flow:

### Implementation Details

- Created stub classes and types that mimic the SDK's API
- Implemented a complete simulation of device discovery, connection, and operation
- The app is fully functional in demo mode for UI demonstration
- When the real SDK is properly integrated, minimal code changes will be required

### Integration Steps for Real SDK

To integrate the real Abloy SDK when available:

1. Add the real SDK to the project:
   - Using CocoaPods (recommended): Update the Podfile and run `pod install`
   - Manual integration: Add the XCFramework to the project

2. Update the code for real SDK integration:
   - Uncomment the `import AbloyCuBeMobileSDK` lines
   - Replace the stub implementations with real SDK calls
   - Follow the Abloy SDK documentation for proper API usage

3. Configure Bluetooth permissions in Info.plist:
   - Add `NSBluetoothAlwaysUsageDescription` for Bluetooth access
   - Add `NSLocationAlwaysAndWhenInUseUsageDescription` for enhanced BLE functionality

4. Test with real devices:
   - Run on a real iOS device with Bluetooth capability
   - Ensure you're within range of Abloy locks

## Features

- Login screen (demo: any non-empty username/password works)
- Home screen showing all garage doors
- Device details screen with ability to open/close garage doors
- Simulated integration with Abloy CuBe Mobile SDK for lock control
- Support for Bluetooth device discovery and connection
- Demo mode with simulated garage doors when no real hardware is available

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Open the `GarageOpenerDemo.xcodeproj` file in Xcode
2. Build and run the app

Note: The app is currently configured to run in demo mode with a stub implementation of the Abloy SDK.

## Project Structure

- `AbloyManager.swift`: Manages the Abloy SDK integration (currently stub implementation)
- `DeviceManager.swift`: Handles garage door state and management
- `Models.swift`: Contains data models for garage doors and SDK types
- `DeviceView.swift`: UI for controlling individual garage doors
- `HomeView.swift`: Displays all available garage doors
- `LoginView.swift`: Handles user authentication

## SDK Integration Details

The app is designed to integrate with the Abloy CuBe Mobile SDK using the following approach:

1. **Initialization**: The SDK is initialized at app startup with appropriate credentials
2. **Device Discovery**: The app uses the SDK's Bluetooth scanning capabilities to discover nearby locks
3. **Connection**: When a user selects a garage door, the app connects to the corresponding lock
4. **Operation**: Lock/unlock commands are sent through the SDK to control the garage door

Currently, these operations are simulated with the stub implementation.

## Usage

The app provides two modes of operation:

### Demo Mode
The app includes a demo mode that simulates garage doors without requiring actual Abloy hardware. 
You can log in with any username and password, and the app will show simulated garage doors that can be controlled.

### Real Device Mode (Future Implementation)
When real Abloy CuBe CUMULUS devices are discovered nearby, the app will:

1. Initialize the Abloy SDK during app startup
2. Scan for nearby locks when you log in
3. Automatically detect Abloy locks in the vicinity
4. Allow you to connect to and operate these locks as garage doors

## Permissions

The app requires the following permissions:
- Bluetooth access for communicating with locks (`NSBluetoothAlwaysUsageDescription`)
- Location services for enhanced Bluetooth functionality (`NSLocationAlwaysAndWhenInUseUsageDescription`)
- Background modes for maintaining Bluetooth connections (`bluetooth-central`)

## Troubleshooting

- **Build Issues**: Make sure to use the `.xcworkspace` file, not the `.xcodeproj` file
- **CocoaPods Issues**: If you encounter problems, try running `pod deintegrate` followed by `pod install`
- **Sandbox Permission Errors**: If building from command line results in sandbox permission errors, try building directly from Xcode instead

## Note

This is a demo application intended to showcase the integration with Abloy CuBe Mobile SDK. 
In a production environment, you would need to implement proper authentication, error handling, and security measures.