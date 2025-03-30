import SwiftUI
import FirebaseFirestore

struct EmployeeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var clientViewModel = ClientViewModel()
    @StateObject private var contractViewModel = ContractViewModel()
    @StateObject private var transferViewModel = TransferViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var contractCount = 0
    @State private var matchCount = 0
    @State private var transferCount = 0
    @State private var clientCount = 0
    @State private var searchText = ""
    @State private var showingLeadSheet = false
    @State private var showingAddClientSheet = false
    @State private var showingAddClubSheet = false
    @State private var showingAddTransferSheet = false
    @State private var showingAddFunktionärSheet = false
    @State private var showingSearchSheet = false
    @State private var showingContactsSheet = false
    @State private var showingSettingsSheet = false
    @State private var selectedTab = 0
    @State private var newClient = Client(typ: "Spieler", name: "", vorname: "", geschlecht: "männlich")
    @State private var newClub = Club(name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
    @State private var newTransfer = Transfer()
    @State private var newFunktionär = Funktionär(name: "", vorname: "")
    @State private var errorMessage = ""

    private var tabs: [(title: String, icon: String, view: AnyView)] {
        [
            ("Dashboard", "chart.bar", AnyView(DashboardView())),
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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = index
                            }
                        }) {
                            Label(tabs[index].title, systemImage: tabs[index].icon)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGray6))

            ZStack {
                ForEach(tabs.indices, id: \.self) { index in
                    tabs[index].view
                        .environmentObject(authManager)
                        .environmentObject(clientViewModel)
                        .environmentObject(contractViewModel)
                        .environmentObject(transferViewModel)
                        .environmentObject(activityViewModel)
                        .opacity(selectedTab == index ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { authManager.signOut() }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.primary)
                }
            }
        }
        .overlay(
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
                        .foregroundColor(selectedTab == 0 ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                    }

                    Menu {
                        Button(action: { showingLeadSheet = true }) {
                            Label("Lead (neuer Lead)", systemImage: "envelope")
                        }
                        Button(action: { showingAddClientSheet = true }) {
                            Label("Klient (neuen Klienten)", systemImage: "person.crop.circle.badge.plus")
                        }
                        Button(action: { showingAddClubSheet = true }) {
                            Label("Verein (neuer Verein)", systemImage: "building.2.fill")
                        }
                        Button(action: { showingAddTransferSheet = true }) {
                            Label("Transfer (neuer Transfer)", systemImage: "arrow.left.arrow.right.circle")
                        }
                        Button(action: { showingAddFunktionärSheet = true }) {
                            Label("Funktionär (neuer Funktionär)", systemImage: "person.badge.key")
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
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    }

                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedTab = tabs.count - 1 } }) {
                        VStack {
                            Image(systemName: "bubble.left")
                                .font(.title2)
                            Text("Chat")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedTab == tabs.count - 1 ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                    }

                    Button(action: { showingContactsSheet = true }) {
                        VStack {
                            Image(systemName: "person.2.fill")
                                .font(.title2)
                            Text("Kontakte")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    }

                    Button(action: { showingSettingsSheet = true }) {
                        VStack {
                            Image(systemName: "gear")
                                .font(.title2)
                            Text("Einstellungen")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 70)
                .background(Color(.systemGray))
                .foregroundColor(.primary)
            },
            alignment: .bottom
        )
        .sheet(isPresented: $showingAddClientSheet) {
            AddClientView(
                client: $newClient,
                isEditing: false,
                onSave: { updatedClient in
                    Task {
                        do {
                            try await FirestoreManager.shared.createClient(client: updatedClient)
                            await MainActor.run {
                                newClient = Client(typ: "Spieler", name: "", vorname: "", geschlecht: "männlich")
                                showingAddClientSheet = false
                            }
                        } catch {
                            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                        }
                    }
                },
                onCancel: {
                    newClient = Client(typ: "Spieler", name: "", vorname: "", geschlecht: "männlich")
                    showingAddClientSheet = false
                }
            )
        }
        .sheet(isPresented: $showingAddClubSheet) {
            AddClubView(
                club: $newClub,
                onSave: { updatedClub in
                    Task {
                        do {
                            try await FirestoreManager.shared.createClub(club: updatedClub)
                            await MainActor.run {
                                newClub = Club(name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
                                showingAddClubSheet = false
                            }
                        } catch {
                            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                        }
                    }
                },
                onCancel: {
                    newClub = Club(name: "", mensDepartment: nil, womensDepartment: nil, sharedInfo: nil)
                    showingAddClubSheet = false
                }
            )
        }
        .sheet(isPresented: $showingAddTransferSheet) {
            AddTransferView(
                isEditing: false,
                initialTransfer: nil,
                onSave: { updatedTransfer in
                    Task {
                        do {
                            try await FirestoreManager.shared.createTransfer(transfer: updatedTransfer)
                            await MainActor.run {
                                showingAddTransferSheet = false
                            }
                        } catch {
                            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                        }
                    }
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
                    Task {
                        do {
                            try await FirestoreManager.shared.createFunktionär(funktionär: updatedFunktionär)
                            await MainActor.run {
                                newFunktionär = Funktionär(name: "", vorname: "")
                                showingAddFunktionärSheet = false
                            }
                        } catch {
                            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                        }
                    }
                },
                onCancel: {
                    newFunktionär = Funktionär(name: "", vorname: "")
                    showingAddFunktionärSheet = false
                }
            )
        }
        .sheet(isPresented: $showingSearchSheet) {
            Text("Appübergreifende Suche (Platzhalter)")
                .onDisappear { showingSearchSheet = false }
        }
        .sheet(isPresented: $showingLeadSheet) {
            ClientContactView(authManager: authManager, isPresented: $showingLeadSheet)
        }
        .sheet(isPresented: $showingContactsSheet) {
            ContactsView()
                .environmentObject(authManager)
                .onDisappear { showingContactsSheet = false }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            UserSettingsView(isPresented: $showingSettingsSheet)
                .environmentObject(authManager)
                .transition(.move(edge: .bottom))
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
        .task {
            await loadCounts()
            // Kein expliziter loadClients()-Aufruf nötig wegen Realtime-Listener
            await contractViewModel.loadContracts()
            await transferViewModel.loadTransfers()
            await activityViewModel.loadActivities()
        }
        .background(Color(.systemBackground))
    }

    private func loadCounts() async {
        do {
            let (contracts, _) = try await FirestoreManager.shared.getContracts(lastDocument: nil, limit: 1000)
            let (matches, _) = try await FirestoreManager.shared.getMatches(lastDocument: nil, limit: 1000)
            let (transfers, _) = try await FirestoreManager.shared.getTransfers(lastDocument: nil, limit: 1000)
            let (clients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            await MainActor.run {
                contractCount = contracts.count
                matchCount = matches.count
                transferCount = transfers.count
                clientCount = clients.count
            }
        } catch {
            errorMessage = "Fehler beim Laden der Zählungen: \(error.localizedDescription)"
        }
    }
}

#Preview {
    EmployeeView()
        .environmentObject(AuthManager())
}
