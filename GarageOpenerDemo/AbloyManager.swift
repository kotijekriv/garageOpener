import Foundation
import Combine
import AbloyCuBeMobileSDK

@MainActor
class AbloyManager: ObservableObject, Sendable {
    @Published var isInitialized = false
    @Published var isScanning = false
    @Published var error: String?
    
    @Published var discoveredLocks: [DiscoveredLock] = []
    
    @Published private(set) var connectedLock: ConnectedLock?
    
    @Published private(set) var lockState: LockingDeviceOperationState?
    
    private var discoveryTask: Task<Void, Never>?
    private var lockEventsTask: Task<Void, Never>?

    // MARK: - Core SDK Functions

    func initializeSDK() async {
        do {
            try await AbloyMobileSDK.shared.initialize()
            self.isInitialized = true
            print("Successfully initialized the Abloy SDK")
        } catch {
            self.error = "Initializing the SDK failed: \(error.localizedDescription)"
            print("Initializing the SDK failed: \(error)")
        }
    }

    // MARK: - Activation & Deactivation

    func activateDevice(with invitationCode: String) async -> Bool {
        do {
            let invitation = try InvitationCode(code: invitationCode)
            print("Activating with self-contained invitation code.")
            try await AbloyMobileSDK.shared.activateOperatingDevice(with: invitation)
            
            let status = try await AbloyMobileSDK.shared.getOperatingDeviceActivationStatus()
            print("Activation successful. Status: \(status)")
            return status == .active
        } catch {
            self.error = "Activation failed: \(error.localizedDescription)"
            print("Device activation failed: \(error)")
            return false
        }
    }
    
    func deactivateDevice() async -> Bool {
        print("Deactivating device...")
        do {
            try await AbloyMobileSDK.shared.deactivateOperatingDevice()
            print("Device deactivated successfully.")
            return true
        } catch {
            self.error = "Deactivating the device failed: \(error.localizedDescription)"
            print("Deactivating the device failed: \(error)")
            return false
        }
    }

    func getActivationStatus() async -> OperatingDeviceActivationStatus? {
        do {
            let status = try await AbloyMobileSDK.shared.getOperatingDeviceActivationStatus()
            print("Current activation status is: \(status)")
            return status
        } catch {
            self.error = "Failed to get activation status: \(error.localizedDescription)"
            print("Failed to get activation status: \(error)")
            return nil
        }
    }

    // MARK: - Discovery & Scanning

    func startScanning() {
        guard isInitialized else { print("SDK not initialized"); return }
        stopScanning()
        print("Starting discovery task...")
        self.isScanning = true
        
        discoveryTask = Task {
            do {
                _ = try await AbloyMobileSDK.shared.fetchAccesses()
                let discoveryStream = AbloyMobileSDK.shared.startLockDiscovery()
                for await event in discoveryStream {
                    if Task.isCancelled { break }
                    handleDiscoveryEvent(event)
                }
            } catch {
                if !(error is CancellationError) {
                    self.error = "Discovery failed: \(error.localizedDescription)"
                    self.isScanning = false
                }
            }
        }
    }
    
    func stopScanning() {
        if isScanning {
            AbloyMobileSDK.shared.stopLockDiscovery()
            discoveryTask?.cancel()
            discoveryTask = nil
            print("Scanning stopped.")
            self.isScanning = false
        }
    }

    // MARK: - Connection & Operations

    func connectToLock(_ device: DiscoveredLock) async -> ConnectedLock? {
        guard connectedLock == nil else { print("Already connected."); return connectedLock }
        
        print("Connecting to lock \(device.hardwareID)...")
        do {
            let lock = try await AbloyMobileSDK.shared.connect(to: device) {
                print("Disconnected unexpectedly.")
                Task { @MainActor in self.cleanUpConnection() }
            }
            self.connectedLock = lock
            print("Successfully connected to lock \(lock.hardwareID).")
            self.listenToLockEvents()
            return lock
        } catch {
            self.error = "Failed to connect: \(error.localizedDescription)"
            return nil
        }
    }
    
    func disconnectFromLock() async {
        guard connectedLock != nil else { return }
        print("Disconnecting from lock...")
        do {
            try await AbloyMobileSDK.shared.disconnectFromLock()
        } catch {
            self.error = "Failed to disconnect: \(error.localizedDescription)"
        }
        cleanUpConnection()
    }

    func unlockGarage() async -> Bool {
        guard let lock = self.connectedLock else {
            print("Cannot unlock: No connected lock.")
            return false
        }
        
        print("Unlocking...")
        do {
            try await AbloyMobileSDK.shared.unlock(connectedLock: lock)
            print("Unlock command successful.")
            return true
        } catch {
            self.error = "Unlock failed: \(error.localizedDescription)"
            return false
        }
    }

    func lockGarage() async -> Bool {
        guard let lock = self.connectedLock else {
            print("Cannot lock: No connected lock.")
            return false
        }
        
        print("Locking...")
        do {
            try await AbloyMobileSDK.shared.lock(connectedLock: lock)
            print("Lock command successful.")
            return true
        } catch {
            self.error = "Lock failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Claiming
    
    func fetchClaimableLocks() async -> [ClaimableLock] {
        print("Fetching claimable locks...")
        do {
            let claimable = try await AbloyMobileSDK.shared.fetchClaimableLocks(page: 0, size: 50)
            print("Found \(claimable.count) claimable locks.")
            return claimable
        } catch {
            self.error = "Failed to fetch claimable locks: \(error.localizedDescription)"
            return []
        }
    }

    func claim(connectedLock: ConnectedLock, with claimableLock: ClaimableLock) async -> Bool {
        print("Attempting to claim lock \(connectedLock.hardwareID) with \(claimableLock.name)...")
        do {
            try await AbloyMobileSDK.shared.claim(connectedLock: connectedLock, with: claimableLock)
            print("Claiming successful!")
            return true
        } catch {
            self.error = "Claiming failed: \(error.localizedDescription)"
            print("Claiming failed: \(error)")
            return false
        }
    }
    
    // MARK: - Accesses

    func fetchUserAccesses() async -> [Access] {
        print("Fetching user accesses...")
        do {
            let result = try await AbloyMobileSDK.shared.fetchAccesses()
            print("Fetched \(result.accesses.count) accesses.")
            return result.accesses
        } catch {
            self.error = "Failed to fetch accesses: \(error.localizedDescription)"
            print("Failed to fetch accesses: \(error)")
            return []
        }
    }

    // MARK: - Private Helper Methods
    
    private func handleDiscoveryEvent(_ event: LockingDeviceDiscoveryEvent) {
        switch event {
        case .discovered(let lock):
            self.handleDiscoveredOrUpdatedLock(lock)
        case .disappeared(let lock):
            self.handleDisappearedLock(lock.hardwareID.uuidString)
        }
    }
    
    private func handleDiscoveredOrUpdatedLock(_ device: DiscoveredLock) {
        if let index = discoveredLocks.firstIndex(where: { $0.hardwareID == device.hardwareID }) {
            debugPrint(device)
            discoveredLocks[index] = device
        } else {
            discoveredLocks.append(device)
        }
    }
    
    private func handleDisappearedLock(_ deviceId: String) {
        discoveredLocks.removeAll { $0.hardwareID.uuidString == deviceId }
    }
    
    private func listenToLockEvents() {
        lockEventsTask?.cancel()
        lockEventsTask = Task {
            print("Started listening to lock events.")
            let eventStream = AbloyMobileSDK.shared.getLockEvents()
            for await event in eventStream {
                if Task.isCancelled { break }
                print("Received lock event: \(event.newState)")
                
                switch event.newState {
                case .operationState(let operationState):
                    self.lockState = operationState
                    print("Lock operation state changed to \(operationState)")
                case .overrideState(let overrideState):
                    print("Lock override state changed to \(overrideState)")
                case .errorState(let errorState):
                    print("Lock error state changed to \(errorState)")
                    self.error = "Lock error: \(errorState)"
                }
            }
            print("Stopped listening to lock events.")
        }
    }
    
    private func cleanUpConnection() {
        self.lockEventsTask?.cancel()
        self.lockEventsTask = nil
        self.connectedLock = nil
        self.lockState = nil
    }
}
