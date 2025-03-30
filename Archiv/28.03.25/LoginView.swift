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

                TextField("E-Mail", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Passwort", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)

                Button(action: { login() }) {
                    Text("Anmelden")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: { showingRegisterSheet = true }) {
                    Text("Registrieren")
                        .foregroundColor(.blue)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Login")
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
                Section(header: Text("Registrierung")) {
                    TextField("E-Mail", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Passwort", text: $password)
                        .autocapitalization(.none)
                    Picker("Rolle", selection: $role) {
                        Text("Mitarbeiter").tag(UserRole.mitarbeiter)
                        Text("Klient").tag(UserRole.klient)
                        Text("Gast").tag(UserRole.gast)
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Registrieren")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
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
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
