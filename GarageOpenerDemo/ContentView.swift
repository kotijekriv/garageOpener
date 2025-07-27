import SwiftUI

struct ContentView: View {
    // ContentView je sada vlasnik instanci i kreira ih kao StateObject.
    // On ih zatim prosljeđuje drugim pogledima putem .environmentObject().
    @StateObject private var deviceManager = DeviceManager()
    @StateObject private var abloyManager = AbloyManager()

    var body: some View {
        Group {
            // Switch koji odlučuje koji se ekran prikazuje na temelju
            // stanja u DeviceManageru.
            switch deviceManager.appState {
            case .loading:
                // 1. Dok se aplikacija učitava, prikazujemo ProgressView.
                ProgressView("Initializing...")
                
            case .needsActivation:
                // 2. Ako je potrebna aktivacija, prikazujemo LoginView.
                LoginView()
                    .environmentObject(deviceManager)
                    .environmentObject(abloyManager)
                
            case .active:
                // 3. Ako je aplikacija aktivna, prikazujemo HomeView.
                HomeView()
                    .environmentObject(deviceManager)
                    .environmentObject(abloyManager)
            }
        }
        // Kada se pogled prvi put pojavi, pokrećemo provjeru početnog stanja.
        .onAppear {
            // Provjeravamo samo ako je stanje `loading` da izbjegnemo ponovno pokretanje
            // ako se pogled iz nekog drugog razloga ponovno iscrta.
            if deviceManager.appState == .loading {
                Task {
                    await deviceManager.checkInitialState(abloyManager: abloyManager)
                }
            }
        }
    }
}
