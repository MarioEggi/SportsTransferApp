import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct SportsTransferApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var transferProcessViewModel: TransferProcessViewModel // Anpassen
    @State private var hasAttemptedAutoLogin = false
    @State private var isLoadingRole = true

    init() {
        FirebaseApp.configure()
        _transferProcessViewModel = StateObject(wrappedValue: TransferProcessViewModel(authManager: AuthManager()))
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
                    EmployeeView(authManager: authManager)
                        .environmentObject(authManager)
                        .environmentObject(transferProcessViewModel)
                        .onAppear {
                            print("EmployeeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                            updateClientsWithUserID()
                        }
                case .klient:
                    ClientHomeView()
                        .environmentObject(authManager)
                        .environmentObject(transferProcessViewModel)
                        .onAppear {
                            print("ClientHomeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                            updateClientsWithUserID()
                        }
                case .gast:
                    HomeView()
                        .environmentObject(authManager)
                        .environmentObject(transferProcessViewModel)
                        .onAppear {
                            print("HomeView (Gast) - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                case .none:
                    HomeView()
                        .environmentObject(authManager)
                        .environmentObject(transferProcessViewModel)
                        .onAppear {
                            print("HomeView (Fallback) - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                default:
                    HomeView()
                        .environmentObject(authManager)
                        .environmentObject(transferProcessViewModel)
                        .onAppear {
                            print("HomeView (Default) - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                }
            } else if !authManager.isLoggedIn {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(transferProcessViewModel)
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

#Preview {
    EmployeeView(authManager: AuthManager())
        .environmentObject(AuthManager())
}
