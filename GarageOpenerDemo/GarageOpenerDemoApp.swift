import SwiftUI

@main
struct GarageOpenerDemoApp: App {
    @StateObject private var deviceManager = DeviceManager()
    @StateObject private var abloyManager = AbloyManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deviceManager)
                .environmentObject(abloyManager)
        }
    }
}
