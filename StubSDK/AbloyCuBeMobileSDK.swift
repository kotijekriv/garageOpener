import Foundation
import Combine

// MARK: - Main SDK Classes

public class AbloySDK {
    public static let shared = AbloySDK()
    
    public let accessManager = AccessManager()
    public let deviceDiscovery = DeviceDiscovery()
    public let deviceConnector = DeviceConnector()
    
    public func initialize(options: SDKInitOptions) async throws {
        print("Initialized Abloy SDK with options: \(options)")
    }
}

public struct SDKInitOptions {
    public let apiKey: String
    public let environment: Environment
    
    public init(apiKey: String, environment: Environment) {
        self.apiKey = apiKey
        self.environment = environment
    }
    
    public enum Environment {
        case production
        case test
    }
}

// MARK: - Access Management

public class AccessManager {
    public func fetchAccesses() async throws -> [Access] {
        return [
            Access(id: "access1", name: "Home Garage"),
            Access(id: "access2", name: "Office Garage")
        ]
    }
}

public struct Access {
    public let id: String
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Device Discovery

public class DeviceDiscovery {
    public func discoverDevices() -> AnyPublisher<DiscoveryEvent, Error> {
        let subject = PassthroughSubject<DiscoveryEvent, Error>()
        
        // Simulate device discovery
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

public struct DiscoveredDevice {
    public let identifier: String
    public let name: String
    public let rssi: Int
    public let isAvailableForConnection: Bool
    
    public init(identifier: String, name: String, rssi: Int, isAvailableForConnection: Bool) {
        self.identifier = identifier
        self.name = name
        self.rssi = rssi
        self.isAvailableForConnection = isAvailableForConnection
    }
}

public enum DiscoveryEvent {
    case discovered(DiscoveredDevice)
    case updated(DiscoveredDevice)
    case disappeared(String) // device identifier
}

// MARK: - Device Connection

public class DeviceConnector {
    public func connect(to device: DiscoveredDevice) async throws -> Lock {
        // Simulate connecting to a device
        print("Connecting to device \(device.identifier)")
        return Lock(identifier: device.identifier, serialNumber: "SN-\(device.identifier)")
    }
    
    public func disconnect(from lock: Lock) async throws {
        // Simulate disconnecting from a device
        print("Disconnecting from device \(lock.identifier)")
    }
}

public class Lock {
    public let identifier: String
    public let serialNumber: String
    public var state: LockState = .unknown
    public let eventPublisher = LockEventPublisher()
    
    public init(identifier: String, serialNumber: String) {
        self.identifier = identifier
        self.serialNumber = serialNumber
    }
    
    public func lock() async throws {
        // This would actually communicate with the lock
        print("Locking device \(identifier)")
        state = .locked
    }
    
    public func unlock() async throws {
        // This would actually communicate with the lock
        print("Unlocking device \(identifier)")
        state = .unlocked
    }
}

// MARK: - Lock State and Events

public enum LockState {
    case unknown
    case locked
    case unlocked
    case operating
    case disconnected
}

public enum LockEvent {
    case stateChanged(LockState)
    case operationProgress(Double)
    case operationCompleted(Bool)
    case error(Error)
}

public class LockEventPublisher {
    public init() {}
    
    public func sink(receiveValue: @escaping (LockEvent) -> Void) -> AnyCancellable {
        let subject = PassthroughSubject<LockEvent, Never>()
        let cancellable = subject.sink(receiveValue: receiveValue)
        
        // Simulate some events
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            subject.send(.stateChanged(.locked))
        }
        
        return cancellable
    }
}