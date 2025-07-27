import SwiftUI
import AbloyCuBeMobileSDK // Potrebno za LockingDeviceOperationState

struct DeviceView: View {
    let garage: GarageDoor
    
    @EnvironmentObject private var deviceManager: DeviceManager
    @EnvironmentObject private var abloyManager: AbloyManager
    
    @State private var isOperating = false
    
    // --- Novi property koji izračunava je li garaža otvorena ---
    // Oslanja se direktno na stanje iz AbloyManagera.
    private var isGarageOpen: Bool {
        // Provjeravamo jesmo li spojeni na ovu konkretnu bravu
        guard abloyManager.connectedLock?.hardwareID == garage.discoveredDevice?.hardwareID,
              let state = abloyManager.lockState else {
            // Ako nismo spojeni, vraćamo zadnje poznato stanje iz modela
            return garage.isOpen
        }
        
        // Vrata su "otvorena" ako je stanje brave 'unlocked'.
        return state == .unlocked
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Garage door visualization
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .shadow(radius: 3)
                    
                    VStack {
                        // Koristimo novi `isGarageOpen` property
                        Image(systemName: isGarageOpen ? "car.fill.garage.open" : "car.fill.garage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .foregroundColor(isGarageOpen ? .green : .blue)
                        
                        Text(isGarageOpen ? "Open" : "Closed")
                            .font(.headline)
                            .padding(.top)
                    }
                }
                .padding(.horizontal)
                
                // Status information
                GroupBox(label: Label("Status", systemImage: "info.circle")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Device:")
                            Spacer()
                            Text(garage.name)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("State:")
                            Spacer()
                            Text(lockStateText)
                                .foregroundColor(isGarageOpen ? .green : .red)
                        }
                        
                        HStack {
                            Text("Connection:")
                            Spacer()
                            Text(connectionStatusText)
                                .foregroundColor(connectionStatusColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Action button
                Button(action: {
                    toggleGarage()
                }) {
                    HStack {
                        Image(systemName: isGarageOpen ? "arrow.down.square.fill" : "arrow.up.square.fill")
                        Text(isGarageOpen ? "Close Garage" : "Open Garage")
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(isGarageOpen ? Color.red : Color.green)
                    .cornerRadius(10)
                }
                .disabled(isOperating || garage.isConnecting)
                .padding(.horizontal)
                
                if isOperating || garage.isConnecting {
                    HStack {
                        ProgressView()
                        Text(garage.isConnecting ? "Connecting..." : "Operating...")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle(garage.name)
        .onAppear(perform: connectOnAppear)
        .onDisappear(perform: disconnectOnDisappear)
    }

    // MARK: - Computed Properties for UI
    
    private var isConnectedToThisGarage: Bool {
        abloyManager.connectedLock?.hardwareID == garage.discoveredDevice?.hardwareID
    }

    private var lockStateText: String {
        guard isConnectedToThisGarage, let state = abloyManager.lockState else {
            return isGarageOpen ? "Open" : "Closed"
        }
        // Pretvaramo stanje iz SDK-a u čitljiv tekst
        switch state {
        case .locked: return "Locked"
        case .unlocked: return "Unlocked"
        case .locking: return "Locking..."
        case .unlocking: return "Unlocking..."
        case .jammed: return "Jammed!"
        case .unknown: return "Unknown"
        }
    }
    
    private var connectionStatusText: String {
        if isConnectedToThisGarage { return "Connected" }
        if garage.discoveredDevice != nil { return "In Range" }
        return "Offline"
    }
    
    private var connectionStatusColor: Color {
        if isConnectedToThisGarage { return .green }
        if garage.discoveredDevice != nil { return .blue }
        return .gray
    }
    
    // MARK: - Private Methods
    
    private func connectOnAppear() {
        guard let discoveredDevice = garage.discoveredDevice, abloyManager.connectedLock == nil else { return }
        Task { await abloyManager.connectToLock(discoveredDevice) }
    }
    
    private func disconnectOnDisappear() {
        if isConnectedToThisGarage {
            Task { await abloyManager.disconnectFromLock() }
        }
    }
    
    private func toggleGarage() {
        isOperating = true
        Task {
            await operateRealGarage()
            self.isOperating = false
        }
    }
    
    private func operateRealGarage() async {
        guard let discoveredDevice = garage.discoveredDevice else { return }

        if !isConnectedToThisGarage {
            let connected = await abloyManager.connectToLock(discoveredDevice)
            guard (connected != nil) else { return }
        }
        
        // Stanje će se samo ažurirati putem `lockState` propertyja.
        if isGarageOpen {
            _ = await abloyManager.lockGarage()
        } else {
            _ = await abloyManager.unlockGarage()
        }
    }
}
