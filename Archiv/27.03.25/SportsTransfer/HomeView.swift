import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var clientViewModel = ClientViewModel()
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var transferViewModel = TransferViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var isDataLoaded = false

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
                    .environmentObject(transferViewModel)
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
                    }
                case .gast, .none:
                    guestDashboard
                case .mitarbeiter:
                    EmptyView()
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
        }
        .navigationTitle("Sports Transfer")
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
                .foregroundColor(colorScheme == .dark ? .white : .black)
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                NavigationLink(destination: ClientView(client: .constant(client))) {
                    Text("Profil anzeigen")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
            .cornerRadius(10)

            Section(header: Text("Mein Vertrag").font(.headline).foregroundColor(colorScheme == .dark ? .white : .black)) {
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
                    .environmentObject(transferViewModel)
                    .environmentObject(activityViewModel)
            } else {
                ProgressView("Lade Dashboard-Daten...")
            }
        }
    }

    private var guestDashboard: some View {
        VStack(spacing: 20) {
            Text("Willkommen als Gast!")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Text("Melde dich an, um alle Funktionen zu nutzen.")
                .foregroundColor(.gray)
            NavigationLink(value: "login") {
                Text("Anmelden")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            NavigationLink(value: "guest") {
                Text("Klienten anzeigen")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }

    private struct ContractCard: View {
        let contract: Contract
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            NavigationLink(destination: ContractDetailView(contract: contract)) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Verein: \(contract.vereinID ?? "Kein Verein")")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    if let endDatum = contract.endDatum {
                        Text("Läuft aus: \(HomeView.dateFormatter.string(from: endDatum))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    private func loadData() async {
        switch authManager.userRole {
        case .mitarbeiter:
            await clientViewModel.loadClients() // Realtime-Listener lädt bereits, aber expliziter Aufruf möglich
            await contractViewModel.loadContracts()
            await transferViewModel.loadTransfers()
            await activityViewModel.loadActivities()
        case .klient:
            if let userID = authManager.userID {
                await clientViewModel.loadClients(userID: userID)
            } else {
                await clientViewModel.loadClients()
            }
            await contractViewModel.loadContracts()
            await transferViewModel.loadTransfers()
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
