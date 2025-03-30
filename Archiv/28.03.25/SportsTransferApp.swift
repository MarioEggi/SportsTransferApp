import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct SportsTransferApp: App {
    @StateObject private var authManager = AuthManager()
    @State private var hasAttemptedAutoLogin = false
    @State private var isLoadingRole = true

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if !hasAttemptedAutoLogin {
                ProgressView("Initialisiere...")
                    .task {
                        authManager.autoLogin()
                        await MainActor.run {
                            hasAttemptedAutoLogin = true
                        }
                    }
            } else if authManager.isLoggedIn && !isLoadingRole {
                switch authManager.userRole {
                case .mitarbeiter:
                    EmployeeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("EmployeeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                            updateClientsWithUserID()
                        }
                case .klient:
                    ClientHomeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("ClientHomeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                            updateClientsWithUserID()
                        }
                case .gast:
                    HomeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("HomeView (Gast) - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                case .none:
                    HomeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("HomeView (Fallback) - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                default:
                    HomeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("HomeView (Default) - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                }
            } else if !authManager.isLoggedIn {
                LoginView()
                    .environmentObject(authManager)
                    .onAppear {
                        print("LoginView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                    }
            } else {
                ProgressView("Lade Benutzerrolle...")
                    .task {
                        if authManager.userID != nil && authManager.userRole == nil {
                            await authManager.loadUserRole(authManager.userID!)
                        }
                        while authManager.userRole == nil && authManager.isLoggedIn {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                        }
                        await MainActor.run {
                            isLoadingRole = false
                        }
                    }
            }
        }
    }

    private func updateClientsWithUserID() {
        guard let userID = authManager.userID else { return }
        Task {
            do {
                try await FirestoreManager.shared.updateClientsWithUserID(userID: userID)
            } catch {
                print("Fehler beim Aktualisieren der userID für Klienten: \(error)")
            }
        }
    }
}
