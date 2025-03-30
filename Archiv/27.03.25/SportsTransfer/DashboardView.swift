import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var clientViewModel: ClientViewModel
    @EnvironmentObject var contractViewModel: ContractViewModel
    @EnvironmentObject var transferViewModel: TransferViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @Environment(\.colorScheme) var colorScheme

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
                        contracts: contractViewModel.expiringContracts(days: 30)
                    )
                    
                    ClientsByClubView(
                        clientsByClub: clientViewModel.activeClientsByClub()
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
        Section(header: Text("Auslaufende Verträge (30 Tage)")
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .white : .black)) {
            if contracts.isEmpty {
                Text("Keine Verträge laufen bald aus.")
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Section(header: Text("Klienten pro Verein")
            .font(.headline)
            .foregroundColor(colorScheme == .dark ? .white : .black)) {
            if clientsByClub.isEmpty {
                Text("Keine Klienten mit Verein.")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(clientsByClub.keys.sorted(), id: \.self) { key in
                            NavigationLink(destination: ClubView(clubID: key)) { // clubID statt Name
                                VStack {
                                    Rectangle()
                                        .frame(width: 20, height: CGFloat(clientsByClub[key]! * 10))
                                        .foregroundColor(.blue)
                                    Text(key)
                                        .font(.caption)
                                        .rotationEffect(.degrees(-45))
                                }
                            }
                        }
                    }
                }
                .frame(height: 100)
                ForEach(clientsByClub.sorted(by: { $0.value > $1.value }), id: \.key) { club, count in
                    NavigationLink(destination: ClubView(clubID: club)) { // clubID statt Name
                        HStack {
                            Text(club)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Text("\(count)")
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
