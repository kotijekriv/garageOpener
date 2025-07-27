import Foundation
import SwiftUI
import AbloyCuBeMobileSDK

// Enum koji definira stanje aplikacije i pomaže nam odlučiti što prikazati korisniku.
enum AppState {
    case loading          // Aplikacija se učitava i provjerava status
    case needsActivation  // Potrebno je prikazati Login ekran za unos koda
    case active           // Aplikacija je aktivna, prikazuje se glavni ekran
}

@MainActor
class DeviceManager: ObservableObject {
    // Glavno stanje aplikacije. Počinje kao 'loading'.
    @Published var appState: AppState = .loading
    
    // Niz garaža koje će se prikazati u korisničkom sučelju.
    @Published var garages: [GarageDoor] = []
    
    // MARK: - Core App Flow
    
    /// Ova funkcija se poziva samo jednom, pri pokretanju aplikacije.
    /// Sada uključuje robusniju logiku za ponovni pokušaj u slučaju greške pri inicijalizaciji SDK-a.
    func checkInitialState(abloyManager: AbloyManager) async {
        // 1. Inicijalizacija se poziva samo JEDNOM, izvan petlje.
        print("Initializing SDK...")
        await abloyManager.initializeSDK()
        
        // Ako je inicijalizacija odmah propala, nema smisla nastavljati.
        if abloyManager.error != nil {
            print("Initial SDK initialization failed. Activation needed.")
            self.appState = .needsActivation
            return
        }
        
        let maxRetries = 5
        var currentTry = 0
        
        while currentTry < maxRetries {
            currentTry += 1
            print("Attempting to get activation status (Attempt \(currentTry)/\(maxRetries))...")
            
            // 2. Samo provjeru statusa pokušavamo više puta.
            let activationStatus = await abloyManager.getActivationStatus()
            
            if let status = activationStatus {
                // Uspjeli smo dobiti status!
                switch status {
                case .active:
                    print("Device is active. Loading garages...")
                    await loadGaragesAfterActivation(abloyManager: abloyManager)
                    self.appState = .active
                    return // Uspjeh, izlazimo.
                case .inactive, .activating:
                    print("Device is not active. Activation needed.")
                    self.appState = .needsActivation
                    return // Validno stanje, izlazimo.
                @unknown default:
                    print("Unknown activation status. Activation needed.")
                    self.appState = .needsActivation
                    return
                }
            }
            
            // Ako je `activationStatus` bio `nil` (greška), čekamo i pokušavamo ponovno.
            print("Failed to get status on attempt \(currentTry). Retrying after a delay...")
            do { try await Task.sleep(nanoseconds: 1_000_000_000) } catch {}
        }
        
        // Ako nismo uspjeli ni nakon svih pokušaja, prikazujemo login.
        print("Could not get activation status after \(maxRetries) attempts.")
        self.appState = .needsActivation
    }
    
    
    
    /// Poziva se s Login ekrana kada korisnik unese pozivni kod.
    func login(invitationCode: String, abloyManager: AbloyManager) async -> Bool {
        guard !invitationCode.isEmpty else { return false }
        
        let success = await abloyManager.activateDevice(with: invitationCode)
        
        if success {
            self.appState = .active
            await loadGaragesAfterActivation(abloyManager: abloyManager)
        }
        return success
    }
    
    /// Poziva se kada se korisnik želi odjaviti.
    func logout(abloyManager: AbloyManager) async {
        await abloyManager.disconnectFromLock()
        let deactivationSuccess = await abloyManager.deactivateDevice()
        
        if deactivationSuccess {
            print("Logout successful, device deactivated.")
        } else {
            print("Logout completed, but deactivation failed. Resetting state locally.")
        }
        
        self.garages = []
        self.appState = .needsActivation
    }
    
    // MARK: - Data Loading & Claiming
    
    /// Dohvaća stvarne garaže (pristupe) nakon uspješne aktivacije.
    func loadGaragesAfterActivation(abloyManager: AbloyManager) async {
        let userAccesses = await abloyManager.fetchUserAccesses()
        
        let realGarages = userAccesses.map { access in
            return GarageDoor(
                id: access.lockID.uuidString,
                name: access.title,
                location: "Remote Access", // Lokaciju nemamo, postavljamo generičku
                isFake: false
            )
        }
        
        if realGarages.isEmpty {
            print("No real accesses found, loading demo garages.")
            loadDemoGarages()
        } else {
            print("Successfully loaded \(realGarages.count) real garages.")
            self.garages = realGarages
        }
    }
    
    /// Pokreće kompletan proces prisvajanja nove brave.
    func claimDevice(unclaimedDevice: DiscoveredLock, abloyManager: AbloyManager) async {
        print("Starting claiming process for device: \(unclaimedDevice.hardwareID)")
        
        // 1. Dohvati "placeholder" sa servera
        let claimableLocks = await abloyManager.fetchClaimableLocks()
        guard let claimableLock = claimableLocks.first else {
            abloyManager.error = "No claimable locks found on server. Please create one first."
            return
        }
        
        // 2. Spoji se na fizičku, neprisvojenu bravu
        guard let connectedLock = await abloyManager.connectToLock(unclaimedDevice) else {
            abloyManager.error = "Could not connect to the physical lock to claim it."
            return
        }
        
        // 3. Pokreni proces prisvajanja
        let success = await abloyManager.claim(connectedLock: connectedLock, with: claimableLock)
        
        // 4. Prekini vezu nakon prisvajanja
        await abloyManager.disconnectFromLock()
        
        if success {
            // 5. Ako je uspjelo, osvježi listu garaža da se pojavi nova
            print("Claiming finished, reloading garages.")
            await self.loadGaragesAfterActivation(abloyManager: abloyManager)
        }
    }
    
    func updateGarageStatuses(basedOn discoveredLocks: [DiscoveredLock]) {
        for i in self.garages.indices {
            let garageId = self.garages[i].id
            // Pronađi odgovarajuću bravu u listi pronađenih
            if let matchingDevice = discoveredLocks.first(where: { $0.hardwareID.uuidString == garageId }) {
                // Ako je pronađena, ažuriraj `discoveredDevice` property na garaži.
                self.garages[i].discoveredDevice = matchingDevice
            } else {
                // Ako više nije u dometu, postavi `discoveredDevice` na nil.
                self.garages[i].discoveredDevice = nil
            }
        }
    }
    
    /// Učitava lažne podatke za demo svrhe.
    private func loadDemoGarages() {
        self.garages = [
            GarageDoor(id: "garage1", name: "Main Garage (Demo)", location: "Home", isFake: true),
            GarageDoor(id: "garage2", name: "Side Garage (Demo)", location: "Home", isOpen: true, isFake: true),
        ]
    }
}
