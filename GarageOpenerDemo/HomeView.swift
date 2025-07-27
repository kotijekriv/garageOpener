import SwiftUI
import AbloyCuBeMobileSDK

struct HomeView: View {
    @EnvironmentObject private var deviceManager: DeviceManager
    @EnvironmentObject private var abloyManager: AbloyManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Prikaz greške ako postoji
                if let error = abloyManager.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .onTapGesture { abloyManager.error = nil }
                }
                
                List {
                    // Prikaz postojećih, prisvojenih garaža
                    Section(header: Text("My Garages")) {
                        if deviceManager.garages.isEmpty {
                            Text("No garages found. Bring a new lock nearby to claim it.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(deviceManager.garages) { garage in
                                NavigationLink(destination: DeviceView(garage: garage)) {
                                    GarageDoorRow(garage: garage)
                                }
                            }
                        }
                    }
                    
                    // Prikaz neprisvojenih brava u blizini
                    if !unclaimedLocks.isEmpty {
                        Section(header: Text("Nearby Unclaimed Devices")) {
                            ForEach(unclaimedLocks, id: \.hardwareID) { device in
                                Button(action: {
                                    // Klikom pokrećemo proces prisvajanja
                                    Task {
                                        await deviceManager.claimDevice(unclaimedDevice: device, abloyManager: abloyManager)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "lock.plus.fill")
                                        Text(device.name ?? "Unnamed Lock")
                                        Spacer()
                                        Text("Tap to claim")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                // --- ISPRAVAK: Uklonjen .refreshable modifikator ---
            }
            .navigationTitle("My Garages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if abloyManager.isScanning {
                            abloyManager.stopScanning()
                        } else {
                            abloyManager.startScanning()
                        }
                    }) {
                        Image(systemName: abloyManager.isScanning ? "antenna.radiowaves.left.and.right.slash" : "antenna.radiowaves.left.and.right")
                    }
                }
                
                // --- NOVO: Gumb za ručno osvježavanje ---
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await deviceManager.loadGaragesAfterActivation(abloyManager: abloyManager)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await deviceManager.logout(abloyManager: abloyManager)
                        }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
        .onAppear {
            if abloyManager.isInitialized && !abloyManager.isScanning {
                abloyManager.startScanning()
            }
        }
        .onChange(of: abloyManager.discoveredLocks) { newDiscoveredLocks in
            deviceManager.updateGarageStatuses(basedOn: newDiscoveredLocks)
        }
    }
    
    private var groupedGarages: [String: [GarageDoor]] {
        Dictionary(grouping: deviceManager.garages, by: { $0.location })
    }
    
    private var unclaimedLocks: [DiscoveredLock] {
        let garageIDs = deviceManager.garages.map { $0.id }
        return abloyManager.discoveredLocks.filter { !garageIDs.contains($0.hardwareID.uuidString) && !$0.isClaimed }
    }
}

struct GarageDoorRow: View {
    let garage: GarageDoor
    
    var body: some View {
        HStack {
            Image(systemName: "car.garage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundColor(garage.isOnline ? .blue : .gray) // Koristi novi isOnline
            
            VStack(alignment: .leading) {
                Text(garage.name)
                    .font(.headline)
                
                // Status tekst se sada oslanja na isOnline
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
        }
    }
    
    private var statusText: String {
        if !garage.isOnline { return "Offline" }
        if garage.isConnecting { return "Connecting..." }
        if garage.isOperating { return "Operating..." }
        return garage.isOpen ? "Open" : "Closed"
    }
    
    private var statusColor: Color {
        if !garage.isOnline { return .gray }
        if garage.isConnecting || garage.isOperating { return .orange }
        return garage.isOpen ? .green : .red
    }
}
