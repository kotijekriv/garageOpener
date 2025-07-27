//
//  AbloyManagerDemo.swift
//  GarageOpenerDemo
//
//  Created by Pero Radić on 26.06.2025..
//
/*
import Foundation
import Combine

// Comment out SDK import until it's properly integrated
import AbloyCuBeMobileSDK
// Stub AbloySDK and related classes
class AbloySDK {
    static let shared = AbloySDK()
    
    let accessManager = AccessManager()
    let deviceDiscovery = DeviceDiscovery()
    let deviceConnector = DeviceConnector()
    
    func initialize(options: SDKInitOptions) async throws {
        print("Initialized Abloy SDK with options: \(options)")
    }
}

struct SDKInitOptions {
    let apiKey: String
    let environment: Environment
    
    enum Environment {
        case production
        case test
    }
}

class AccessManager {
    func fetchAccesses() async throws -> [Access] {
        return [
            Access(id: "access1", name: "Home Garage"),
            Access(id: "access2", name: "Office Garage")
        ]
    }
}

struct Access {
    let id: String
    let name: String
}

class DeviceConnector {
    func connect(to device: DiscoveredDevice) async throws -> Lock {
        print("Connecting to device \(device.identifier)")
        return Lock(identifier: device.identifier, serialNumber: "SN-\(device.identifier)")
    }
    
    func disconnect(from lock: Lock) async throws {
        print("Disconnecting from device \(lock.identifier)")
    }
}

class DeviceDiscovery {
    func discoverDevices() -> AnyPublisher<DiscoveryEvent, Error> {
        let subject = PassthroughSubject<DiscoveryEvent, Error>()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let device = DiscoveredDevice(
                identifier: "device1",
                name: "Garage Lock",
                rssi: -65,
                isAvailableForConnection: true
            )
            subject.send(.discovered(device))
        }
        
        return subject.eraseToAnyPublisher()
    }
}

enum DiscoveryEvent {
    case discovered(DiscoveredDevice)
    case updated(DiscoveredDevice)
    case disappeared(String)
}

class AbloyManager: ObservableObject {
    @Published var isInitialized = false
    @Published var isScanning = false
    @Published var error: String?
    
    private var discoveredLocks: [DiscoveredDevice] = []
    private var connectedLock: Lock?
    private var lockEventSubscription: AnyCancellable?
    private var discoverySubscription: AnyCancellable?
    
    // Initialize the Abloy SDK
    func initializeSDK() async {
        do {
            try await AbloySDK.shared.initialize(
                options: SDKInitOptions(
                    apiKey: "your-api-key",
                    environment: .production
                )
            )
            
            DispatchQueue.main.async {
                self.isInitialized = true
                print("Successfully initialized the Abloy SDK")
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Initializing the SDK failed: \(error)"
                print("Initializing the SDK failed: \(error)")
            }
        }
    }
    
    // Start scanning for locks
    func startScanning() {
        guard isInitialized else {
            print("SDK not initialized")
            return
        }
        
        // First fetch accesses (in real app)
        Task {
            do {
                // Fetch available accesses for the user
                _ = try await AbloySDK.shared.accessManager.fetchAccesses()
                
                // Start lock discovery
                discoverySubscription = AbloySDK.shared.deviceDiscovery.discoverDevices()
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("Discovery error: \(error)")
                            }
                        },
                        receiveValue: { [weak self] discoveryEvent in
                            switch discoveryEvent {
                            case .discovered(let device):
                                self?.handleDiscoveredLock(device)
                            case .updated(let device):
                                self?.handleUpdatedLock(device)
                            case .disappeared(let deviceId):
                                self?.handleDisappearedLock(deviceId)
                            }
                        }
                    )
                
                DispatchQueue.main.async {
                    self.isScanning = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Failed to fetch accesses: \(error)"
                    print("Failed to fetch accesses: \(error)")
                }
            }
        }
    }
    
    // Stop scanning for locks
    func stopScanning() {
        discoverySubscription?.cancel()
        discoverySubscription = nil
        
        DispatchQueue.main.async {
            self.isScanning = false
        }
    }
    
    // Connect to a lock
    func connectToLock(_ device: DiscoveredDevice, forGarage garage: GarageDoor) async -> Bool {
        do {
            // Connect to the lock
            let lock = try await AbloySDK.shared.deviceConnector.connect(to: device)
            
            // Subscribe to lock events
            subscribeToLockEvents(lock)
            
            self.connectedLock = lock
            return true
        } catch {
            print("Failed to connect to lock: \(error)")
            return false
        }
    }
    
    // Disconnect from the current lock
    func disconnectFromLock() async {
        guard let lock = connectedLock else { return }
        
        do {
            try await AbloySDK.shared.deviceConnector.disconnect(from: lock)
            self.connectedLock = nil
            lockEventSubscription?.cancel()
            lockEventSubscription = nil
        } catch {
            print("Error disconnecting from lock: \(error)")
        }
    }
    
    // Unlock a garage door
    func unlockGarage(_ garage: GarageDoor) async -> Bool {
        guard let lock = self.connectedLock else {
            print("No connected lock")
            return false
        }
        
        do {
            try await lock.unlock()
            return true
        } catch {
            print("Failed to unlock: \(error)")
            return false
        }
    }
    
    // Lock a garage door
    func lockGarage(_ garage: GarageDoor) async -> Bool {
        guard let lock = self.connectedLock else {
            print("No connected lock")
            return false
        }
        
        do {
            try await lock.lock()
            return true
        } catch {
            print("Failed to lock: \(error)")
            return false
        }
    }
    
    // MARK: - Private methods
    
    private func handleDiscoveredLock(_ device: DiscoveredDevice) {
        print("Discovered lock: \(device.identifier)")
        discoveredLocks.append(device)
        
        // In a real app, you would match the discovered lock with your garage doors
        // For demo, we'll just print it
    }
    
    private func handleUpdatedLock(_ device: DiscoveredDevice) {
        print("Updated lock: \(device.identifier)")
        if let index = discoveredLocks.firstIndex(where: { $0.identifier == device.identifier }) {
            discoveredLocks[index] = device
        }
    }
    
    private func handleDisappearedLock(_ deviceId: String) {
        print("Lock disappeared: \(deviceId)")
        discoveredLocks.removeAll { $0.identifier == deviceId }
    }
    
    private func subscribeToLockEvents(_ lock: Lock) {
        lockEventSubscription = lock.eventPublisher
            .sink { [weak self] event in
                DispatchQueue.main.async {
                    switch event {
                    case .stateChanged(let state):
                        print("Lock state changed: \(state)")
                        // Update UI based on lock state
                        
                    case .operationProgress(let progress):
                        print("Lock operation progress: \(progress)")
                        
                    case .operationCompleted(let result):
                        print("Lock operation completed: \(result)")
                        
                    case .error(let error):
                        print("Lock error: \(error)")
                    }
                }
            }
    }
}

*/
