import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct SportsTransferApp: App {
    @StateObject private var authManager = AuthManager()
    @State private var hasAttemptedAutoLogin = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                switch authManager.userRole {
                case .mitarbeiter:
                    EmployeeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("EmployeeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                        }
                case .klient:
                    ClientHomeView()
                        .environmentObject(authManager)
                        .onAppear {
                            print("ClientHomeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
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
                }
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .onAppear {
                        if !hasAttemptedAutoLogin {
                            authManager.autoLogin()
                            hasAttemptedAutoLogin = true
                        }
                        print("LoginView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                    }
            }
        }
    }
}
