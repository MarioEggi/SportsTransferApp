//
//  LoginView.swift

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showingRegisterSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Anmelden")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white) // Weiße Schrift

                TextField("E-Mail", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .foregroundColor(.white) // Weiße Schrift
                    .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                    .cornerRadius(8)

                SecureField("Passwort", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .foregroundColor(.white) // Weiße Schrift
                    .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                    .cornerRadius(8)

                Button(action: { login() }) {
                    Text("Anmelden")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white) // Weiße Schrift
                        .cornerRadius(10)
                }

                Button(action: { showingRegisterSheet = true }) {
                    Text("Registrieren")
                        .foregroundColor(.white) // Weiße Schrift
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .background(Color.black) // Schwarzer Hintergrund für die gesamte View
            .navigationTitle("Login")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .sheet(isPresented: $showingRegisterSheet) {
                RegisterView()
            }
        }
    }

    private func login() {
        authManager.login(email: email, password: password) { result in
            switch result {
            case .success:
                errorMessage = ""
            case .failure(let error):
                errorMessage = "Anmeldung fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var role: UserRole = .gast
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Registrierung").foregroundColor(.white)) {
                    TextField("E-Mail", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .foregroundColor(.white) // Weiße Schrift
                    SecureField("Passwort", text: $password)
                        .autocapitalization(.none)
                        .foregroundColor(.white) // Weiße Schrift
                    Picker("Rolle", selection: $role) {
                        Text("Mitarbeiter").tag(UserRole.mitarbeiter)
                        Text("Klient").tag(UserRole.klient)
                        Text("Gast").tag(UserRole.gast)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.white) // Weiße Schrift
                    .accentColor(.white) // Weiße Akzente
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
            .background(Color.black) // Schwarzer Hintergrund für die Form
            .navigationTitle("Registrieren")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.white) // Weiße Schrift
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Registrieren") {
                        authManager.register(email: email, password: password, role: role) { result in
                            switch result {
                            case .success:
                                dismiss()
                            case .failure(let error):
                                errorMessage = "Registrierung fehlgeschlagen: \(error.localizedDescription)"
                            }
                        }
                    }
                    .foregroundColor(.white) // Weiße Schrift
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
