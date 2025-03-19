import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var clients: [Client] = []
    @State private var contracts: [Contract] = []
    @State private var activities: [Activity] = []
    @State private var transfers: [Transfer] = []
    @State private var errorMessage = ""
    @State private var currentClient: Client?
    @State private var showingAddClientSheet = false
    @State private var showingAddClubSheet = false
    @State private var showingAddTransferSheet = false
    @State private var showingAddFunktionärSheet = false
    @State private var showingLeadSheet = false
    @State private var showingContactsSheet = false
    @State private var showingSearchSheet = false
    @State private var showingLoginView = false // Neue State-Variable für Navigation
    @State private var showingGuestView = false // Neue State-Variable für Navigation
    @State private var newClient = Client(
        id: nil,
        typ: "Spieler",
        name: "",
        vorname: "",
        geschlecht: "männlich",
        vereinID: nil,
        nationalitaet: [],
        geburtsdatum: nil,
        liga: nil,
        profilbildURL: nil
    )
    @State private var newClub = Club(name: "")
    @State private var newTransfer = Transfer()
    @State private var newFunktionär = Funktionär(
        id: nil,
        name: "",
        vorname: "",
        kontaktTelefon: nil,
        kontaktEmail: nil,
        adresse: nil,
        clients: nil
    )
    @State private var selectedTab = 0

    private var tabs: [(title: String, icon: String, view: AnyView)] {
        [
            ("Home", "house", AnyView(HomeDashboardView(clients: clients, contracts: contracts, activities: activities, transfers: transfers))),
            ("Klienten", "person.2", AnyView(ClientListView())),
            ("Verträge", "doc.text", AnyView(ContractListView())),
            ("Vereine", "building.2", AnyView(ClubListView())),
            ("Transfers", "arrow.left.arrow.right", AnyView(TransferListView())),
            ("Spiele", "sportscourt", AnyView(MatchListView())),
            ("Sponsoren", "dollarsign.circle", AnyView(SponsorListView())),
            ("Funktionäre", "person.badge.key", AnyView(FunktionärListView())),
            ("Chat", "bubble.left", AnyView(ChatView()))
        ]
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            if authManager.userRole == .mitarbeiter {
                employeeView
            } else {
                guestOrClientView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { authManager.signOut() }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
            }
        }
        .overlay(customBar, alignment: .bottom)
        .sheet(isPresented: $showingAddClientSheet) {
            AddClientView(
                client: $newClient,
                isEditing: false,
                onSave: { updatedClient in
                    saveClient(updatedClient)
                },
                onCancel: {
                    resetNewClient()
                    showingAddClientSheet = false
                }
            )
        }
        .sheet(isPresented: $showingAddClubSheet) {
            AddClubView(
                club: $newClub,
                onSave: { updatedClub in
                    saveClub(updatedClub)
                },
                onCancel: {
                    newClub = Club(name: "")
                    showingAddClubSheet = false
                }
            )
        }
        .sheet(isPresented: $showingAddTransferSheet) {
            AddTransferView(
                isEditing: false,
                initialTransfer: nil,
                onSave: { updatedTransfer in
                    saveTransfer(updatedTransfer)
                },
                onCancel: {
                    showingAddTransferSheet = false
                }
            )
        }
        .sheet(isPresented: $showingAddFunktionärSheet) {
            AddFunktionärView(
                funktionär: $newFunktionär,
                onSave: { updatedFunktionär in
                    saveFunktionär(updatedFunktionär)
                },
                onCancel: {
                    newFunktionär = Funktionär(id: nil, name: "", vorname: "", kontaktTelefon: nil, kontaktEmail: nil, adresse: nil, clients: nil)
                    showingAddFunktionärSheet = false
                }
            )
        }
        .sheet(isPresented: $showingLeadSheet) {
            ClientContactView(authManager: authManager, isPresented: $showingLeadSheet)
        }
        .sheet(isPresented: $showingContactsSheet) {
            ContactsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingSearchSheet) {
            Text("Appübergreifende Suche (Platzhalter)")
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .task {
            Task {
                await loadData()
            }
        }
    }

    private var employeeView: some View {
        NavigationSplitView {
            List(tabs.indices, id: \.self) { index in
                NavigationLink(destination: tabs[index].view.environmentObject(authManager)) {
                    Label(tabs[index].title, systemImage: tabs[index].icon)
                        .foregroundColor(selectedTab == index ? .blue : .gray)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }
            }
            .navigationTitle("Sports Transfer")
        } detail: {
            tabs[selectedTab].view
                .environmentObject(authManager)
        }
    }

    private var guestOrClientView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                switch authManager.userRole {
                case .klient:
                    if let client = currentClient {
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
        }
        .navigationTitle("Sports Transfer")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Willkommen\(authManager.userEmail.map { ", \($0)" } ?? "")")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Deine Plattform für Klienten und Verträge")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    struct HomeDashboardView: View {
        @EnvironmentObject var authManager: AuthManager
        let clients: [Client]
        let contracts: [Contract]
        let activities: [Activity]
        let transfers: [Transfer]

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 15) {
                        StatCard(title: "Klienten", count: clients.count, icon: "person.2")
                        StatCard(title: "Verträge", count: contracts.count, icon: "doc.text")
                        StatCard(title: "Transfers", count: transfers.count, icon: "arrow.left.arrow.right")
                    }
                    HStack(spacing: 15) {
                        NavigationLink(destination: ClientListView()) {
                            DashboardButton(title: "Klienten", icon: "person.3.fill", color: .blue)
                        }
                        NavigationLink(destination: ContractListView()) {
                            DashboardButton(title: "Verträge", icon: "doc.text.fill", color: .green)
                        }
                        NavigationLink(destination: ContactsView()) {
                            DashboardButton(title: "Kontakte", icon: "phone.fill", color: .purple)
                        }
                    }
                    Section(header: Text("Anstehende Verträge").font(.headline)) {
                        if contracts.isEmpty {
                            Text("Keine Verträge vorhanden.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(contracts.filter { isDateInNextMonth($0.endDatum) }) { contract in
                                ContractCard(contract: contract)
                            }
                        }
                    }
                    Section(header: Text("Letzte Aktivitäten").font(.headline)) {
                        if activities.isEmpty {
                            Text("Keine Aktivitäten vorhanden.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(activities.prefix(3)) { activity in
                                ActivityCard(activity: activity)
                            }
                        }
                    }
                }
                .padding()
            }
        }

        private func isDateInNextMonth(_ date: Date?) -> Bool {
            guard let date = date else { return false }
            let calendar = Calendar.current
            let now = Date()
            var components = DateComponents()
            components.month = 1
            guard let nextMonth = calendar.date(byAdding: components, to: now) else { return false }
            let dateComponents = calendar.dateComponents([.year, .month], from: date)
            let nextMonthComponents = calendar.dateComponents([.year, .month], from: nextMonth)
            return dateComponents.year == nextMonthComponents.year && dateComponents.month == nextMonthComponents.month
        }
    }

    private func clientDashboard(client: Client) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mein Profil")
                    .font(.headline)
                HStack {
                    if let profilbildURL = client.profilbildURL, let url = URL(string: profilbildURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    }
                    VStack(alignment: .leading) {
                        Text("\(client.vorname) \(client.name)")
                            .font(.title3)
                            .bold()
                        if let vereinID = client.vereinID {
                            Text(vereinID)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                NavigationLink(destination: ClientView(client: .constant(client))) {
                    Text("Profil anzeigen")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            Section(header: Text("Mein Vertrag").font(.headline)) {
                if let contract = contracts.first(where: { $0.clientID == client.id }) {
                    ContractCard(contract: contract)
                } else {
                    Text("Kein Vertrag vorhanden.")
                        .foregroundColor(.gray)
                }
            }
            Section(header: Text("Meine Aktivitäten").font(.headline)) {
                if activities.isEmpty {
                    Text("Keine Aktivitäten vorhanden.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(activities.prefix(3)) { activity in
                        ActivityCard(activity: activity)
                    }
                }
            }
        }
    }

    private var guestDashboard: some View {
        VStack(spacing: 20) {
            Text("Willkommen als Gast!")
                .font(.headline)
            Text("Melde dich an, um alle Funktionen zu nutzen.")
                .foregroundColor(.gray)
            NavigationLink(isActive: $showingLoginView) {
                LoginView()
            } label: {
                Text("Anmelden")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            NavigationLink(isActive: $showingGuestView) {
                GuestView()
            } label: {
                Text("Klienten anzeigen")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }

    private var customBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = 0 } }) {
                    VStack {
                        Image(systemName: "house")
                            .font(.title2)
                        Text("Home")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedTab == 0 ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                }
                Menu {
                    if authManager.userRole == .mitarbeiter {
                        Button(action: { showingLeadSheet = true }) {
                            Label("Lead", systemImage: "envelope")
                        }
                        Button(action: { showingAddClientSheet = true }) {
                            Label("Klient", systemImage: "person.crop.circle.badge.plus")
                        }
                        Button(action: { showingAddClubSheet = true }) {
                            Label("Verein", systemImage: "building.2.fill")
                        }
                        Button(action: { showingAddTransferSheet = true }) {
                            Label("Transfer", systemImage: "arrow.left.arrow.right.circle")
                        }
                        Button(action: { showingAddFunktionärSheet = true }) {
                            Label("Funktionär", systemImage: "person.badge.key")
                        }
                    } else if authManager.userRole == .klient {
                        Button(action: { showingLeadSheet = true }) {
                            Label("Kontakt aufnehmen", systemImage: "envelope")
                        }
                    }
                } label: {
                    VStack {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                        Text("Create")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                }
                Button(action: { showingSearchSheet = true }) {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                        Text("Suche")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                }
                if authManager.userRole == .mitarbeiter || authManager.userRole == .klient {
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = tabs.count - 1 } }) {
                        VStack {
                            Image(systemName: "bubble.left")
                            .font(.title2)
                            Text("Chat")
                            .font(.caption)
                            .lineLimit(1)
                        }
                        .foregroundColor(selectedTab == tabs.count - 1 && authManager.userRole == .mitarbeiter ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                    }
                }
                Button(action: { showingContactsSheet = true }) {
                    VStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                        Text("Kontakte")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70)
            .background(Color.black)
            .foregroundColor(.white)
        }
    }

    private struct DashboardButton: View {
        let title: String
        let icon: String
        let color: Color

        var body: some View {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }

    private struct ContractCard: View {
        let contract: Contract

        var body: some View {
            NavigationLink(destination: ContractDetailView(contract: contract)) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Verein: \(contract.vereinID ?? "Kein Verein")")
                        .font(.subheadline)
                    if let endDatum = contract.endDatum {
                        Text("Läuft aus: \(HomeView.dateFormatter.string(from: endDatum))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    private struct ActivityCard: View {
        let activity: Activity

        var body: some View {
            NavigationLink(destination: ActivityDetailView(activity: activity)) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(activity.description)
                        .lineLimit(1)
                    Text(activity.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    private func loadData() async {
        switch authManager.userRole {
        case .mitarbeiter:
            do {
                let loadedClients = try await FirestoreManager.shared.getClients()
                let loadedContracts = try await FirestoreManager.shared.getContracts()
                let loadedActivities = try await FirestoreManager.shared.getActivities(forClientID: "")
                let loadedTransfers = try await FirestoreManager.shared.getTransfers()
                await MainActor.run {
                    self.clients = loadedClients
                    self.contracts = loadedContracts
                    self.activities = loadedActivities
                    self.transfers = loadedTransfers
                }
            } catch {
                handleError(error)
            }
        case .klient:
            guard let userID = authManager.userID else { return }
            do {
                let loadedClients = try await FirestoreManager.shared.getClients()
                if let client = loadedClients.first(where: { $0.userID == userID }) {
                    let contract = try await FirestoreManager.shared.getContract(forClientID: client.id ?? "")
                    let loadedActivities = try await FirestoreManager.shared.getActivities(forClientID: client.id ?? "")
                    await MainActor.run {
                        self.currentClient = client
                        self.contracts = contract != nil ? [contract!] : []
                        self.activities = loadedActivities
                    }
                }
            } catch {
                handleError(error)
            }
        case .gast, .none:
            do {
                let loadedClients = try await FirestoreManager.shared.getClients()
                await MainActor.run { self.clients = loadedClients }
            } catch {
                handleError(error)
            }
        }
    }

    private func saveClient(_ client: Client) {
        Task {
            do {
                try await FirestoreManager.shared.createClient(client: client)
                await loadData()
                await MainActor.run {
                    resetNewClient()
                    showingAddClientSheet = false
                }
            } catch {
                handleError(error)
                await MainActor.run {
                    showingAddClientSheet = false
                }
            }
        }
    }

    private func saveClub(_ club: Club) {
        Task {
            do {
                try await FirestoreManager.shared.createClub(club: club)
                await loadData()
                await MainActor.run {
                    newClub = Club(name: "")
                    showingAddClubSheet = false
                }
            } catch {
                handleError(error)
                await MainActor.run {
                    showingAddClubSheet = false
                }
            }
        }
    }

    private func saveTransfer(_ transfer: Transfer) {
        Task {
            do {
                try await FirestoreManager.shared.createTransfer(transfer: transfer)
                await loadData()
                await MainActor.run {
                    showingAddTransferSheet = false
                }
            } catch {
                handleError(error)
                await MainActor.run {
                    showingAddTransferSheet = false
                }
            }
        }
    }

    private func saveFunktionär(_ funktionär: Funktionär) {
        Task {
            do {
                try await FirestoreManager.shared.createFunktionär(funktionär: funktionär)
                await loadData()
                await MainActor.run {
                    newFunktionär = Funktionär(id: nil, name: "", vorname: "", kontaktTelefon: nil, kontaktEmail: nil, adresse: nil, clients: nil)
                    showingAddFunktionärSheet = false
                }
            } catch {
                handleError(error)
                await MainActor.run {
                    showingAddFunktionärSheet = false
                }
            }
        }
    }

    private func handleError(_ error: Error) {
        Task { @MainActor in
            errorMessage = "Fehler: \(error.localizedDescription)"
        }
    }

    private func resetNewClient() {
        newClient = Client(
            id: nil,
            typ: "Spieler",
            name: "",
            vorname: "",
            geschlecht: "männlich",
            vereinID: nil,
            nationalitaet: [],
            geburtsdatum: nil,
            liga: nil,
            profilbildURL: nil
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
}
