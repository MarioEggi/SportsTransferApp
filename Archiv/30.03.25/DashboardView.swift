import SwiftUI
import FirebaseFirestore

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var clientViewModel: ClientViewModel
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var transferProcessViewModel: TransferProcessViewModel
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var clubs: [Club] = []
    @State private var errorMessage: String = ""

    init() {
        _clientViewModel = StateObject(wrappedValue: ClientViewModel(authManager: AuthManager()))
        _transferProcessViewModel = StateObject(wrappedValue: TransferProcessViewModel(authManager: AuthManager()))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DueRemindersView(
                        reminders: transferProcessViewModel.dueReminders
                    )
                    
                    BasicStatsView(
                        clientCount: clientViewModel.clients.count,
                        contractCount: contractViewModel.contracts.count,
                        transferCount: transferProcessViewModel.transferProcesses.count
                    )
                    
                    ExpiringContractsView(
                        contracts: expiringContractsUntilNextJune30()
                    )
                    
                    ClientsByClubView(
                        clientsByClub: clientViewModel.activeClientsByClub(),
                        clubs: clubs
                    )
                    
                    RecentTransferProcessesView(
                        transferProcesses: transferProcessViewModel.transferProcesses.filter { process in
                            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
                            return process.startDatum >= cutoffDate
                        }
                    )
                    
                    RecentActivitiesView(
                        activities: activityViewModel.recentActivities(days: 7)
                    )
                }
                .padding()
                .background(Color.black) // Schwarzer Hintergrund
            }
            .navigationTitle("Dashboard")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .task {
                await loadClubs()
                await transferProcessViewModel.loadTransferProcesses()
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(.white),
                    message: Text(errorMessage).foregroundColor(.white),
                    dismissButton: .default(Text("OK").foregroundColor(.white)) {
                        errorMessage = ""
                    }
                )
            }
        }
        .environmentObject(clientViewModel)
        .environmentObject(transferProcessViewModel)
    }

    private func loadClubs() async {
        do {
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            await MainActor.run {
                self.clubs = loadedClubs
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }

    private func expiringContractsUntilNextJune30() -> [Contract] {
        let calendar = Calendar.current
        let today = Date()
        guard let nextJune30 = calendar.date(from: DateComponents(year: calendar.component(.year, from: today), month: 6, day: 30)) else {
            return []
        }
        let adjustedNextJune30 = today > nextJune30 ? calendar.date(byAdding: .year, value: 1, to: nextJune30) : nextJune30
        return contractViewModel.contracts.filter { contract in
            guard let endDatum = contract.endDatum else { return false }
            return endDatum <= adjustedNextJune30!
        }
    }
}

struct BasicStatsView: View {
    let clientCount: Int
    let contractCount: Int
    let transferCount: Int

    var body: some View {
        Section(header: Text("Statistiken").font(.headline).foregroundColor(.white)) {
            HStack(spacing: 10) {
                StatCard(title: "Klienten", value: "\(clientCount)", icon: "person.2")
                StatCard(title: "Verträge", value: "\(contractCount)", icon: "doc.text")
                StatCard(title: "Transfers", value: "\(transferCount)", icon: "arrow.left.arrow.right")
            }
        }
    }

    struct StatCard: View {
        let title: String
        let value: String
        let icon: String

        var body: some View {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white) // Weißes Symbol
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white) // Weiße Schrift
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white) // Weiße Schrift
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)
        }
    }
}

struct ExpiringContractsView: View {
    let contracts: [Contract]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        Section(header: Text("Auslaufende Verträge (bis 30. Juni)").font(.headline).foregroundColor(.white)) {
            if contracts.isEmpty {
                Text("Keine auslaufenden Verträge.")
                    .foregroundColor(.gray)
            } else {
                ForEach(contracts.prefix(5)) { contract in
                    ContractItemView(contract: contract)
                }
            }
        }
    }

    struct ContractItemView: View {
        let contract: Contract
        @EnvironmentObject var clientViewModel: ClientViewModel

        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                if let client = clientViewModel.clients.first(where: { $0.id == contract.clientID }) {
                    Text("\(client.vorname) \(client.name)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white) // Weiße Schrift
                }
                if let endDatum = contract.endDatum {
                    Text("Läuft aus: \(dateFormatter.string(from: endDatum))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if let vereinID = contract.vereinID {
                    Text("Verein: \(vereinID)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)
        }
    }
}

struct ClientsByClubView: View {
    let clientsByClub: [String: Int]
    let clubs: [Club]

    var body: some View {
        Section(header: Text("Klienten pro Verein").font(.headline).foregroundColor(.white)) {
            if clientsByClub.isEmpty {
                Text("Keine Klienten vorhanden.")
                    .foregroundColor(.gray)
            } else {
                ForEach(clientsByClub.sorted(by: { $0.value > $1.value }), id: \.key) { clubID, count in
                    if let club = clubs.first(where: { $0.id == clubID }) {
                        ClubClientItemView(club: club, clientCount: count)
                    }
                }
            }
        }
    }

    struct ClubClientItemView: View {
        let club: Club
        let clientCount: Int

        var body: some View {
            HStack {
                if let logoURL = club.sharedInfo?.logoURL, let url = URL(string: logoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "building.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "building.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                Text(club.name)
                    .font(.subheadline)
                    .foregroundColor(.white) // Weiße Schrift
                Spacer()
                Text("\(clientCount) Klienten")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)
        }
    }
}

struct RecentTransferProcessesView: View {
    let transferProcesses: [TransferProcess]
    @EnvironmentObject var transferProcessViewModel: TransferProcessViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        Section(header: Text("Letzte Transferprozesse (30 Tage)").font(.headline).foregroundColor(.white)) {
            if transferProcesses.isEmpty {
                Text("Keine kürzlichen Transferprozesse.")
                    .foregroundColor(.gray)
            } else {
                ForEach(transferProcesses.prefix(5)) { process in
                    TransferProcessItemView(process: process)
                }
            }
        }
    }

    struct TransferProcessItemView: View {
        let process: TransferProcess
        @EnvironmentObject var transferProcessViewModel: TransferProcessViewModel

        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                if let client = transferProcessViewModel.clients.first(where: { $0.id == process.clientID }) {
                    Text("\(client.vorname) \(client.name)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white) // Weiße Schrift
                }
                if let club = transferProcessViewModel.clubs.first(where: { $0.id == process.vereinID }) {
                    Text("Verein: \(club.name)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Text("Start: \(dateFormatter.string(from: process.startDatum))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Status: \(process.status)")
                    .font(.caption)
                    .foregroundColor(process.status == "abgeschlossen" ? .green : .orange)
            }
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)
        }
    }
}

struct RecentActivitiesView: View {
    let activities: [Activity]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Section(header: Text("Letzte Aktivitäten (7 Tage)").font(.headline).foregroundColor(.white)) {
            if activities.isEmpty {
                Text("Keine kürzlichen Aktivitäten.")
                    .foregroundColor(.gray)
            } else {
                ForEach(activities.prefix(5)) { activity in
                    ActivityItemView(activity: activity)
                }
            }
        }
    }

    struct ActivityItemView: View {
        let activity: Activity

        private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.white) // Weiße Schrift
                Text(dateFormatter.string(from: activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
            .cornerRadius(10)
        }
    }
}

struct DueRemindersView: View {
    let reminders: [Reminder]
    
    var body: some View {
        Section(header: Text("Fällige Erinnerungen")
            .font(.headline)
            .foregroundColor(.white)) {
            if reminders.isEmpty {
                Text("Keine fälligen Erinnerungen.")
                    .foregroundColor(.gray)
            } else {
                ForEach(reminders) { reminder in
                    ReminderItemView(reminder: reminder)
                }
            }
        }
    }
}

struct ReminderItemView: View {
    let reminder: Reminder
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Datum: \(Self.dateFormatter.string(from: reminder.datum))")
                .font(.subheadline)
                .foregroundColor(.red)
            Text(reminder.beschreibung)
                .font(.body)
                .foregroundColor(.white) // Weiße Schrift
        }
        .padding()
        .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
        .cornerRadius(10)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthManager())
        .environmentObject(ClientViewModel(authManager: AuthManager()))
        .environmentObject(ContractViewModel())
        .environmentObject(TransferProcessViewModel(authManager: AuthManager()))
        .environmentObject(ActivityViewModel())
}
