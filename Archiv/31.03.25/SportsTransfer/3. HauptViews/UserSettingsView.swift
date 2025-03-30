import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var vorname: String = ""
    @State private var strasse: String = ""
    @State private var nr: String = ""
    @State private var plz: String = ""
    @State private var ort: String = ""
    @State private var land: String = ""
    @State private var telefonnummer: String = ""
    @State private var email: String = ""
    @State private var newPassword: String = ""
    @State private var currentPassword: String = "" // Für Re-Authentifizierung
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var isEditing: Bool = false // Bearbeitungsmodus

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Persönliche Daten")) {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("Vorname", text: $vorname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("Straße", text: $strasse)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("Nr.", text: $nr)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("PLZ", text: $plz)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("Ort", text: $ort)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("Land", text: $land)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    TextField("Telefonnummer", text: $telefonnummer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.done)
                }
                
                Section(header: Text("Kontoinformationen")) {
                    TextField("E-Mail", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    SecureField("Neues Passwort", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.next)
                    SecureField("Aktuelles Passwort", text: $currentPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!isEditing)
                        .submitLabel(.done)
                    Button("Passwort und E-Mail ändern") {
                        updateCredentials()
                    }
                    .disabled(!isEditing || (email.isEmpty && newPassword.isEmpty) || isLoading)
                }
                
                Section {
                    Button(isEditing ? "Speichern" : "Bearbeiten") {
                        if isEditing {
                            saveUserData()
                        } else {
                            isEditing = true
                        }
                    }
                    .disabled(isLoading)
                    
                    Button("Abmelden") {
                        authManager.signOut()
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) { errorMessage = "" }
                )
            }
            .task {
                await loadUserData()
            }
            .overlay(
                isLoading ? ProgressView("Speichere...").progressViewStyle(CircularProgressViewStyle()) : nil
            )
        }
    }

    private func loadUserData() async {
        guard let userID = authManager.userID else { return }
        do {
            let document = try await db.collection("users").document(userID).getDocument()
            if let data = document.data() {
                await MainActor.run {
                    name = data["name"] as? String ?? ""
                    vorname = data["vorname"] as? String ?? ""
                    strasse = data["strasse"] as? String ?? ""
                    nr = data["nr"] as? String ?? ""
                    plz = data["plz"] as? String ?? ""
                    ort = data["ort"] as? String ?? ""
                    land = data["land"] as? String ?? ""
                    telefonnummer = data["telefonnummer"] as? String ?? ""
                    email = authManager.userEmail ?? ""
                }
            }
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
        }
    }

    private func saveUserData() {
        guard let userID = authManager.userID else {
            errorMessage = "Kein Benutzer angemeldet"
            return
        }
        // Validierung
        if name.isEmpty || vorname.isEmpty {
            errorMessage = "Name und Vorname sind Pflichtfelder"
            return
        }
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = "Ungültiges E-Mail-Format"
            return
        }
        
        isLoading = true
        let userData: [String: Any] = [
            "name": name,
            "vorname": vorname,
            "strasse": strasse,
            "nr": nr,
            "plz": plz,
            "ort": ort,
            "land": land,
            "telefonnummer": telefonnummer,
            "email": email,
            "rolle": authManager.userRole?.rawValue ?? UserRole.gast.rawValue
        ]
        db.collection("users").document(userID).setData(userData, merge: true) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                } else {
                    self.isEditing = false
                }
            }
        }
    }

    private func updateCredentials() {
        guard !currentPassword.isEmpty else {
            errorMessage = "Bitte gib dein aktuelles Passwort ein"
            return
        }
        if !email.isEmpty && !isValidEmail(email) {
            errorMessage = "Ungültiges E-Mail-Format"
            return
        }
        
        isLoading = true
        let credential = EmailAuthProvider.credential(withEmail: authManager.userEmail ?? "", password: currentPassword)
        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Erneute Authentifizierung fehlgeschlagen: \(error.localizedDescription)"
                    isLoading = false
                }
                return
            }
            if !email.isEmpty, email != authManager.userEmail {
                authManager.updateEmail(newEmail: email) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            if newPassword.isEmpty { isLoading = false; isEditing = false }
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                            isLoading = false
                        }
                    }
                }
            }
            if !newPassword.isEmpty {
                authManager.updatePassword(newPassword: newPassword) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        switch result {
                        case .success:
                            newPassword = ""
                            currentPassword = ""
                            isEditing = false
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: email)
    }
}

#Preview {
    UserSettingsView(isPresented: .constant(true))
        .environmentObject(AuthManager())
}
