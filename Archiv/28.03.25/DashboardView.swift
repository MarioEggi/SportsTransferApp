import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var clientViewModel: ClientViewModel
    @EnvironmentObject var contractViewModel: ContractViewModel
    @EnvironmentObject var transferViewModel: TransferViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var clubs: [Club] = []
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    BasicStatsView(
                        clientCount: clientViewModel.clients.count,
                        contractCount: contractViewModel.contracts.count,
                        transferCount: transferViewModel.transfers.count
                    )
                    
                    ExpiringContractsView(
                        contracts: expiringContractsUntilNextJune30()
                    )
                    
                    ClientsByClubView(
                        clientsByClub: clientViewModel.activeClientsByClub(),
                        clubs: clubs
                    )
                    
                    RecentTransfersView(
                        transfers: transferViewModel.recentTransfers(days: 30)
                    )
                    
                    RecentActivitiesView(
                        activities: activityViewModel.recentActivities(days: 7)
                    )
                }
                .padding()
                .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            }
            .navigationTitle("Dashboard")
            .task {
                await loadClubs()
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = ""
                    }
                )
            }
        }
    }

    // Hilfsfunktion, um den nächsten 30. Juni zu berechnen
    private func nextJune30() -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Aktuelles Jahr
        let currentYear = calendar.component(.year, from: today)
        
        // 30. Juni des aktuellen Jahres
        var components = DateComponents()
        components.year = currentYear
        components.month = 6
        components.day = 30
        let june30ThisYear = calendar.date(from: components)!
        
        // Wenn heute vor oder am 30. Juni ist, ist der nächste 30. Juni in diesem Jahr
        if today <= june30ThisYear {
            return june30ThisYear
        } else {
            // Sonst ist der nächste 30. Juni im nächsten Jahr
            components.year = currentYear + 1
            return calendar.date(from: components)!
        }
    }
    
    // Hilfsfunktion, um Verträge zu filtern, die nicht über den nächsten 30. Juni hinausgehen
    private func expiringContractsUntilNextJune30() -> [Contract] {
        let nextJune30Date = nextJune30()
        return contractViewModel.contracts.filter { contract in
            guard let endDatum = contract.endDatum else { return false }
            return endDatum <= nextJune30Date
        }
    }

    private func loadClubs() async {
        do {
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            await MainActor.run {
                clubs = loadedClubs
            }
        } catch {
            errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
        }
    }
}

struct BasicStatsView: View {
    let clientCount: Int
    let contractCount: Int
    let transferCount: Int
    
    var body: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Klienten",
                count: clientCount,
                icon: "person.2",
                destination: AnyView(ClientListView())
            )
            StatCard(
                title: "Verträge",
                count: contractCount,
                icon: "doc.text",
                destination: AnyView(ContractListView())
            )
            StatCard(
                title: "Transfers",
                count: transferCount,
                icon: "arrow.left.arrow.right",
                destination: AnyView(TransferListView())
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String
    let destination: AnyView
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .frame(width: 80, height: 80)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct ExpiringContractsView: View {
    let contracts: [Contract]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: Text("Auslaufende Verträge")
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .white : .black)) {
            if contracts.isEmpty {
                Text("Keine Verträge laufen vor dem nächsten 30. Juni aus.")
                    .foregroundColor(.gray)
            } else {
                ForEach(contracts) { contract in
                    ContractItemView(contract: contract)
                }
            }
        }
    }
}

struct ContractItemView: View {
    let contract: Contract
    @Environment(\.colorScheme) var colorScheme
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: ContractDetailView(contract: contract)) {
            VStack(alignment: .leading) {
                Text("Verein: \(contract.vereinID ?? "Unbekannt")")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                if let endDatum = contract.endDatum {
                    Text("Läuft aus: \(Self.dateFormatter.string(from: endDatum))")
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

struct ClientsByClubView: View {
    let clientsByClub: [String: Int]
    let clubs: [Club]
    @Environment(\.colorScheme) var colorScheme
    
    // Hilfsfunktion, um den Vereinsnamen anhand der ID zu finden
    private func clubName(for clubID: String) -> String {
        if let club = clubs.first(where: { $0.id == clubID }) {
            return club.name
        }
        return clubID // Fallback auf die ID, falls der Verein nicht gefunden wird
    }
    
    var body: some View {
        Section(header: Text("Klienten pro Verein")
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .white : .black)) {
            if clientsByClub.isEmpty {
                Text("Keine Klienten mit Verein.")
                    .foregroundColor(.gray)
            } else {
                // Liste der Vereine mit Klientenanzahl
                ForEach(clientsByClub.sorted(by: { $0.value > $1.value }), id: \.key) { clubID, count in
                    NavigationLink(destination: ClubView(clubID: clubID)) {
                        HStack {
                            Text(clubName(for: clubID))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Text("\(count)")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}

struct RecentTransfersView: View {
    let transfers: [Transfer]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: Text("Letzte Transfers (30 Tage)")
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .white : .black)) {
            if transfers.isEmpty {
                Text("Keine Transfers in den letzten 30 Tagen.")
                    .foregroundColor(.gray)
            } else {
                ForEach(transfers) { transfer in
                    TransferItemView(transfer: transfer)
                }
            }
        }
    }
}

struct TransferItemView: View {
    let transfer: Transfer
    @Environment(\.colorScheme) var colorScheme
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: TransferDetailView(transfer: transfer)) {
            VStack(alignment: .leading) {
                Text("Von: \(transfer.vonVereinID ?? "Unbekannt")")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text("Zu: \(transfer.zuVereinID ?? "Unbekannt")")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text("Datum: \(Self.dateFormatter.string(from: transfer.datum))")
                    .font(.caption)
                    .foregroundColor(.gray)
                if let ablösesumme = transfer.ablösesumme, !transfer.isAblösefrei {
                    Text("Ablösesumme: \(String(format: "%.2f", ablösesumme)) €")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if transfer.isAblösefrei {
                    Text("Ablösefrei")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct RecentActivitiesView: View {
    let activities: [Activity]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: Text("Letzte Aktivitäten")
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .white : .black)) {
            if activities.isEmpty {
                Text("Keine Aktivitäten vorhanden.")
                    .foregroundColor(.gray)
            } else {
                ForEach(activities.prefix(5)) { activity in
                    NavigationLink(destination: ActivityDetailView(activity: activity)) {
                        VStack(alignment: .leading) {
                            Text(activity.description)
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text(DateFormatter.mediumWithTime.string(from: activity.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}

extension DateFormatter {
    static let mediumWithTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    DashboardView()
        .environmentObject(ClientViewModel())
        .environmentObject(ContractViewModel())
        .environmentObject(TransferViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(AuthManager())
}
