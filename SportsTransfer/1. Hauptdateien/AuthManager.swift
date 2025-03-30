import FirebaseAuth
import FirebaseFirestore
import Foundation

enum UserRole: String, Codable {
    case mitarbeiter = "Mitarbeiter"
    case klient = "Klient"
    case gast = "Gast"
}

class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userRole: UserRole?
    @Published var userEmail: String?
    @Published var userID: String?
    @Published var errorMessage: String?
    private var authHandle: AuthStateDidChangeListenerHandle?

    var currentUser: User? {
        return Auth.auth().currentUser
    }

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                self.isLoggedIn = true
                self.userEmail = user.email
                self.userID = user.uid
                print("Benutzer angemeldet: \(user.uid), E-Mail: \(user.email ?? "Keine")")
                Task {
                    await self.loadUserRole(user.uid)
                }
            } else {
                self.isLoggedIn = false
                self.userRole = nil
                self.userEmail = nil
                self.userID = nil
                print("Kein Benutzer angemeldet")
            }
        }
    }

    func loadUserRole(_ uid: String) async {
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            let data = snapshot.data()
            print("Firestore-Daten für UID \(uid): \(String(describing: data))")
            if let roleString = data?["rolle"] as? String, let role = UserRole(rawValue: roleString) {
                await MainActor.run {
                    self.userRole = role
                    print("Rolle gesetzt: \(role.rawValue)")
                }
            } else {
                await MainActor.run {
                    self.userRole = .gast
                    print("Keine gültige Rolle gefunden, auf Gast zurückgefallen")
                }
            }
        } catch {
            print("Fehler beim Laden der Rolle: \(error.localizedDescription)")
            await MainActor.run {
                self.userRole = .gast
                self.errorMessage = "Fehler beim Laden der Rolle: \(error.localizedDescription)"
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                self.userEmail = user.email
                self.userID = user.uid
                self.isLoggedIn = true
                Task {
                    await self.loadUserRole(user.uid)
                }
                completion(.success(()))
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.userRole = nil
                self.userEmail = nil
                self.userID = nil
            }
        } catch {
            print("Logout fehlgeschlagen: \(error.localizedDescription)")
            self.errorMessage = "Logout fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func register(email: String, password: String, role: UserRole, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer konnte nicht erstellt werden"])))
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "email": email,
                "rolle": role.rawValue
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.userEmail = email
                    self.userID = user.uid
                    self.userRole = role
                    self.isLoggedIn = true
                    completion(.success(()))
                }
            }
        }
    }

    func createClientLogin(email: String, password: String, clientID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer konnte nicht erstellt werden"])))
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(userID).setData([
                "email": email,
                "rolle": UserRole.klient.rawValue,
                "clientID": clientID
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                db.collection("clients").document(clientID).updateData([
                    "userID": userID
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }

    func autoLogin() {
        let defaultEmail = "eggimann@t-online.de"
        let defaultPassword = "test123"
        login(email: defaultEmail, password: defaultPassword) { result in
            switch result {
            case .success:
                print("Automatischer Login erfolgreich für \(defaultEmail)")
            case .failure(let error):
                print("Automatischer Login fehlgeschlagen: \(error.localizedDescription)")
                self.errorMessage = "Autologin fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    func updateEmail(newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Benutzer angemeldet"])))
            return
        }
        user.updateEmail(to: newEmail) { [weak self] error in
            if let error = error {
                self?.errorMessage = "E-Mail-Änderung fehlgeschlagen: \(error.localizedDescription)"
                completion(.failure(error))
            } else {
                self?.userEmail = newEmail
                self?.updateEmailInFirestore(newEmail: newEmail)
                completion(.success(()))
            }
        }
    }

    func updatePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Benutzer angemeldet"])))
            return
        }
        user.updatePassword(to: newPassword) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Passwort-Änderung fehlgeschlagen: \(error.localizedDescription)"
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func updateEmailInFirestore(newEmail: String) {
        guard let userID = userID else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData(["email": newEmail]) { error in
            if let error = error {
                print("Fehler beim Aktualisieren der E-Mail in Firestore: \(error.localizedDescription)")
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
