import SwiftUI

struct LoginView: View {
    // --- PROMJENA #1: Koristimo jedan state za pozivni kod ---
    @State private var invitationCode = ""
    @State private var showError = false
    @State private var isActivating = false // Za prikaz ProgressView-a
    
    @EnvironmentObject private var deviceManager: DeviceManager
    // Potrebno je dodati i AbloyManager u Environment
    @EnvironmentObject private var abloyManager: AbloyManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo or app title
                VStack {
                    Image(systemName: "lock.rectangle.stack.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("Garage Opener")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 50)
                
                // Login form
                VStack(spacing: 20) {
                    TextField("Invitation Code", text: $invitationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .textContentType(.oneTimeCode)
                    
                    if isActivating {
                        ProgressView("Activating...")
                            .padding()
                    } else {
                        Button(action: activateDevice) {
                            HStack {
                                Text("Activate Device")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    if showError {
                        Text("Activation Failed. Please check the code and try again.")
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text("Enter the invitation code provided by the system administrator.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                    .padding(.horizontal)
            }
            .navigationBarTitle("", displayMode: .inline)
        }
    }
    
    private func activateDevice() {
        // Sakrij staru grešku i pokreni indikator
        showError = false
        isActivating = true
        
        // Pokreni asinkroni zadatak
        Task {
            let success = await deviceManager.login(
                invitationCode: invitationCode,
                abloyManager: abloyManager
            )
            
            // Kada je zadatak gotov, ugasi indikator
            isActivating = false
            
            // Ako nije uspjelo, prikaži grešku
            if !success {
                showError = true
            }
        }
    }
}
