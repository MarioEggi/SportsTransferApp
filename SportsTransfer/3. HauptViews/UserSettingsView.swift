import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
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
    @State private var currentPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var isEditing: Bool = false
    @State private var user: User?

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Gamify").foregroundColor(textColor)) {
                        if let user = user {
                            HStack {
                                Text("Punkte: \(user.points ?? 0)")
                                    .foregroundColor(textColor)
                                Spacer()
                                NavigationLink(destination: LeaderboardView()) {
                                    Text("Rangliste anzeigen")
                                        .foregroundColor(accentColor)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        } else {
                            Text("Punkte werden geladen...")
                                .foregroundColor(secondaryTextColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )

                    Section(header: Text("Persönliche Daten").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("Name", text: $name)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("Vorname", text: $vorname)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("Straße", text: $strasse)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("Nr.", text: $nr)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("PLZ", text: $plz)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("Ort", text: $ort)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("Land", text: $land)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            TextField("Telefonnummer", text: $telefonnummer)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )

                    Section(header: Text("Kontoinformationen").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            TextField("E-Mail", text: $email)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            SecureField("Neues Passwort", text: $newPassword)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            SecureField("Aktuelles Passwort", text: $currentPassword)
                                .foregroundColor(textColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .disabled(!isEditing)
                            Button("Passwort und E-Mail ändern") {
                                updateCredentials()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .foregroundColor(textColor)
                            .cornerRadius(10)
                            .disabled(!isEditing || (email.isEmpty && newPassword.isEmpty) || isLoading)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )

                    Section {
                        Button(isEditing ? "Speichern" : "Bearbeiten") {
                            if isEditing { saveUserData() } else { isEditing = true }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentColor)
                        .foregroundColor(textColor)
                        .cornerRadius(10)
                        .disabled(isLoading)
                        Button("Abmelden") {
                            authManager.signOut()
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(textColor)
                        .cornerRadius(10)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .tint(accentColor)
                .foregroundColor(textColor)
                .navigationTitle("Einstellungen")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { isPresented = false }
                            .foregroundColor(accentColor)
                    }
                }
                .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) { errorMessage = "" }
                    )
                }
                .task {
                    await loadUserData()
                    await loadUser()
                }
                .overlay(
                    isLoading ? ProgressView("Speichere...").tint(accentColor) : nil
                )
            }
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

    private func loadUser() async {
        guard let userID = authManager.userID else { return }
        do {
            let snapshot = try await db.collection("users").document(userID).getDocument()
            user = try snapshot.data(as: User.self)
        } catch {
            errorMessage = "Fehler beim Laden des Benutzers: \(error.localizedDescription)"
        }
    }

    private func saveUserData() {
        guard let userID = authManager.userID else {
            errorMessage = "Kein Benutzer angemeldet"
            return
        }
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
