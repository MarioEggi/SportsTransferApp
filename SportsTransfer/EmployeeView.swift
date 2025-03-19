import SwiftUI
import FirebaseFirestore

struct EmployeeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var contractCount = 0
    @State private var matchCount = 0
    @State private var transferCount = 0
    @State private var clientCount = 0
    @State private var searchText = ""
    @State private var clients: [Client] = []
    @State private var filteredClients: [Client] = []
    @State private var showingLeadSheet = false
    @State private var showingAddClientSheet = false
    @State private var showingAddClubSheet = false
    @State private var showingAddTransferSheet = false
    @State private var showingAddFunktionärSheet = false
    @State private var showingSearchSheet = false
    @State private var showingContactsSheet = false
    @State private var selectedTab = 0
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

    // Definition der Tabs mit Titel, Symbol und zugehöriger Ansicht
    private let tabs: [(title: String, icon: String, view: AnyView)] = [
        ("Home", "house", AnyView(HomeView())),
        ("Klienten", "person.2", AnyView(ClientListView())),
        ("Verträge", "doc.text", AnyView(ContractListView())),
        ("Vereine", "building.2", AnyView(ClubListView())),
        ("Transfers", "arrow.left.arrow.right", AnyView(TransferListView())),
        ("Spiele", "sportscourt", AnyView(MatchListView())),
        ("Sponsoren", "dollarsign.circle", AnyView(SponsorListView())),
        ("Funktionäre", "person.badge.key", AnyView(FunktionärListView())),
        ("Chat", "bubble.left", AnyView(ChatView()))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Scrollbare Tab-Leiste
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = index
                            }
                        }) {
                            Label(tabs[index].title, systemImage: tabs[index].icon)
                                .foregroundColor(selectedTab == index ? .blue : .gray)
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

            // Hauptansicht basierend auf dem ausgewählten Tab mit Animation
            ZStack {
                ForEach(tabs.indices, id: \.self) { index in
                    tabs[index].view
                        .environmentObject(authManager)
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
                }
            }
        }
        .sheet(isPresented: $showingAddClientSheet) {
            AddClientView(
                client: $newClient,
                isEditing: false,
                onSave: { updatedClient in
                    Task {
                        do {
                            try await FirestoreManager.shared.createClient(client: updatedClient)
                            await loadClients()
                            await MainActor.run {
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
                        } catch {
                            await MainActor.run {
                                print("Fehler beim Speichern: \(error.localizedDescription)")
                            }
                        }
                        await MainActor.run {
                            showingAddClientSheet = false
                        }
                    }
                },
                onCancel: {
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
                            await loadClients()
                            await MainActor.run {
                                newClub = Club(name: "")
                            }
                        } catch {
                            await MainActor.run {
                                print("Fehler beim Speichern: \(error.localizedDescription)")
                            }
                        }
                        await MainActor.run {
                            showingAddClubSheet = false
                        }
                    }
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
                    Task {
                        do {
                            try await FirestoreManager.shared.createTransfer(transfer: updatedTransfer)
                            await loadClients()
                        } catch {
                            await MainActor.run {
                                print("Fehler beim Speichern: \(error.localizedDescription)")
                            }
                        }
                        await MainActor.run {
                            showingAddTransferSheet = false
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
                            await loadClients()
                            await MainActor.run {
                                newFunktionär = Funktionär(
                                    id: nil,
                                    name: "",
                                    vorname: "",
                                    kontaktTelefon: nil,
                                    kontaktEmail: nil,
                                    adresse: nil,
                                    clients: nil
                                )
                            }
                        } catch {
                            await MainActor.run {
                                print("Fehler beim Speichern: \(error.localizedDescription)")
                            }
                        }
                        await MainActor.run {
                            showingAddFunktionärSheet = false
                        }
                    }
                },
                onCancel: {
                    newFunktionär = Funktionär(
                        id: nil,
                        name: "",
                        vorname: "",
                        kontaktTelefon: nil,
                        kontaktEmail: nil,
                        adresse: nil,
                        clients: nil
                    )
                    showingAddFunktionärSheet = false
                }
            )
        }
        .sheet(isPresented: $showingSearchSheet) {
            Text("Appübergreifende Suche (Platzhalter)")
                .onDisappear {
                    showingSearchSheet = false
                }
        }
        .sheet(isPresented: $showingLeadSheet) {
            ClientContactView(authManager: authManager, isPresented: $showingLeadSheet)
        }
        .sheet(isPresented: $showingContactsSheet) {
            ContactsView()
                .environmentObject(authManager)
                .onDisappear {
                    showingContactsSheet = false
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
                        .foregroundColor(selectedTab == 0 ? .blue : .gray)
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
                        .foregroundColor(.gray)
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
                        .foregroundColor(selectedTab == tabs.count - 1 ? .blue : .gray)
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
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 70)
                .background(Color.black)
                .foregroundColor(.white)
            },
            alignment: .bottom
        )
        .task {
            await loadCounts()
            await loadClients()
        }
    }

    private func loadCounts() async {
        do {
            let contracts = try await FirestoreManager.shared.getContracts()
            await MainActor.run { contractCount = contracts.count }
            let matches = try await FirestoreManager.shared.getMatches()
            await MainActor.run { matchCount = matches.count }
            let transfers = try await FirestoreManager.shared.getTransfers()
            await MainActor.run { transferCount = transfers.count }
            let loadedClients = try await FirestoreManager.shared.getClients()
            await MainActor.run {
                clients = loadedClients
                clientCount = loadedClients.count
                applySearch()
            }
        } catch {
            await MainActor.run {
                print("Fehler beim Laden der Zählungen: \(error.localizedDescription)")
                contractCount = 0
                matchCount = 0
                transferCount = 0
                clientCount = 0
            }
        }
    }

    private func loadClients() async {
        do {
            let loadedClients = try await FirestoreManager.shared.getClients()
            await MainActor.run {
                clients = loadedClients
                clientCount = loadedClients.count
                applySearch()
            }
        } catch {
            await MainActor.run {
                clients = []
                clientCount = 0
                applySearch()
            }
        }
    }

    private func applySearch() {
        if searchText.isEmpty {
            filteredClients = clients
        } else {
            filteredClients = clients.filter {
                $0.vorname.lowercased().contains(searchText.lowercased()) ||
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

#Preview {
    EmployeeView()
        .environmentObject(AuthManager())
}
