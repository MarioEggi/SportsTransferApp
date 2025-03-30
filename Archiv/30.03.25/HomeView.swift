import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var clientViewModel: ClientViewModel
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var transferProcessViewModel: TransferProcessViewModel
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var isDataLoaded = false

    init() {
        _clientViewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
        _transferProcessViewModel = StateObject(wrappedValue: TransferProcessViewModel(authManager: AuthManager()))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            if authManager.userRole == .mitarbeiter {
                DashboardView()
                    .environmentObject(clientViewModel)
                    .environmentObject(contractViewModel)
                    .environmentObject(transferProcessViewModel)
                    .environmentObject(activityViewModel)
            } else {
                guestOrClientView
            }
        }
        .task {
            await loadData()
            await MainActor.run { isDataLoaded = true }
        }
    }

    private var guestOrClientView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                switch authManager.userRole {
                case .klient:
                    if let client = clientViewModel.clients.first(where: { $0.userID == authManager.userID }) {
                        clientDashboard(client: client)
                    } else {
                        ProgressView("Lade Klientendaten...")
                            .tint(.white) // Weißer Ladeindikator
                    }
                case .gast, .none:
                    guestDashboard
                case .mitarbeiter:
                    EmptyView()
                }
            }
            .padding()
            .background(Color.black) // Schwarzer Hintergrund
        }
        .navigationTitle("Sports Transfer")
        .foregroundColor(.white) // Weiße Schrift für den Titel
        .navigationDestination(for: String.self) { value in
            if value == "login" {
                LoginView()
            } else if value == "guest" {
                GuestView()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Willkommen\(authManager.userEmail.map { ", \($0)" } ?? "")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white) // Weiße Schrift
            Text("Deine Plattform für Klienten und Verträge")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private func clientDashboard(client: Client) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mein Profil")
                    .font(.headline)
                    .foregroundColor(.white) // Weiße Schrift
                NavigationLink(destination: ClientView(client: .constant(client))) {
                    Text("Profil anzeigen")
                        .font(.subheadline)
                        .foregroundColor(.white) // Weiße Schrift
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)

            Section(header: Text("Mein Vertrag").font(.headline).foregroundColor(.white)) {
                if let contract = contractViewModel.contracts.first(where: { $0.clientID == client.id }) {
                    ContractCard(contract: contract)
                } else {
                    Text("Kein Vertrag vorhanden.")
                        .foregroundColor(.gray)
                }
            }

            if isDataLoaded {
                DashboardView()
                    .environmentObject(clientViewModel)
                    .environmentObject(contractViewModel)
                    .environmentObject(transferProcessViewModel)
                    .environmentObject(activityViewModel)
            } else {
                ProgressView("Lade Dashboard-Daten...")
                    .tint(.white) // Weißer Ladeindikator
            }
        }
    }

    private var guestDashboard: some View {
        VStack(spacing: 20) {
            Text("Willkommen als Gast!")
                .font(.headline)
                .foregroundColor(.white) // Weiße Schrift
            Text("Melde dich an, um alle Funktionen zu nutzen.")
                .foregroundColor(.gray)
            NavigationLink(value: "login") {
                Text("Anmelden")
                    .font(.subheadline)
                    .foregroundColor(.white) // Weiße Schrift
            }
            NavigationLink(value: "guest") {
                Text("Klienten anzeigen")
                    .font(.subheadline)
                    .foregroundColor(.white) // Weiße Schrift
            }
        }
    }

    private struct ContractCard: View {
        let contract: Contract

        var body: some View {
            NavigationLink(destination: ContractDetailView(contract: contract)) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Verein: \(contract.vereinID ?? "Kein Verein")")
                        .font(.subheadline)
                        .foregroundColor(.white) // Weiße Schrift
                    if let endDatum = contract.endDatum {
                        Text("Läuft aus: \(HomeView.dateFormatter.string(from: endDatum))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                .cornerRadius(10)
            }
        }
    }

    private func loadData() async {
        switch authManager.userRole {
        case .mitarbeiter:
            await clientViewModel.loadClients()
            await contractViewModel.loadContracts()
            await transferProcessViewModel.loadTransferProcesses()
            await activityViewModel.loadActivities()
        case .klient:
            if let userID = authManager.userID {
                await clientViewModel.loadClients(userID: userID)
            } else {
                await clientViewModel.loadClients()
            }
            await contractViewModel.loadContracts()
            await transferProcessViewModel.loadTransferProcesses()
            await activityViewModel.loadActivities()
        case .gast, .none:
            await clientViewModel.loadClients()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
}
