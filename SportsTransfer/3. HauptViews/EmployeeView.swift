import SwiftUI
import FirebaseFirestore

struct EmployeeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var transferProcessViewModel: TransferProcessViewModel
    @State private var showingNewChatSheet = false
    @State private var selectedPartner: String? = nil
    @State private var potentialChatPartners: [(id: String, name: String)] = []
    @State private var errorMessage: String = ""
    @State private var chats: [Chat] = []
    @State private var navigateToChat: Chat? = nil // Für die Navigation zum neuen Chat
    @State private var selectedTab: String = "workflow" // Für die Tab-Auswahl

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Workflow Tab
                WorkflowOverviewView()
                    .tabItem {
                        Label("Workflow", systemImage: "list.bullet")
                            .environment(\.symbolVariants, selectedTab == "workflow" ? .fill : .none)
                    }
                    .tag("workflow")
                    .environmentObject(authManager)
                    .environmentObject(transferProcessViewModel)

                // Clients Tab
                ClientListView()
                    .tabItem {
                        Label("Klienten", systemImage: "person.3")
                            .environment(\.symbolVariants, selectedTab == "clients" ? .fill : .none)
                    }
                    .tag("clients")
                    .environmentObject(authManager)

                // Clubs Tab
                ClubListView()
                    .tabItem {
                        Label("Vereine", systemImage: "building.2")
                            .environment(\.symbolVariants, selectedTab == "clubs" ? .fill : .none)
                    }
                    .tag("clubs")
                    .environmentObject(authManager)

                // Funktionäre Tab
                FunktionärListView()
                    .tabItem {
                        Label("Funktionäre", systemImage: "person.crop.circle.badge.checkmark")
                            .environment(\.symbolVariants, selectedTab == "funktionäre" ? .fill : .none)
                    }
                    .tag("funktionäre")
                    .environmentObject(authManager)
                    .environmentObject(FunktionärViewModel())

                // Chats Tab
                ChatListView(
                    showingNewChatSheet: $showingNewChatSheet,
                    selectedPartner: $selectedPartner,
                    potentialChatPartners: $potentialChatPartners,
                    errorMessage: $errorMessage,
                    chats: $chats,
                    onChatCreated: { newChat in
                        Task {
                            await loadChats()
                            // Setze den neuen Chat für die Navigation
                            await MainActor.run {
                                navigateToChat = newChat
                            }
                        }
                    }
                )
                .tabItem {
                    Label("Chats", systemImage: "message")
                        .environment(\.symbolVariants, selectedTab == "chats" ? .fill : .none)
                }
                .tag("chats")
                .environmentObject(authManager)

                // Matching Tab
                MatchingView()
                    .tabItem {
                        Label("Matching", systemImage: "person.2")
                            .environment(\.symbolVariants, selectedTab == "matching" ? .fill : .none)
                    }
                    .tag("matching")
                    .environmentObject(authManager)

                // More Tab (für Sponsoren, Verträge, Spiele und Einstellungen)
                MoreView(
                    showingNewChatSheet: $showingNewChatSheet,
                    selectedPartner: $selectedPartner,
                    potentialChatPartners: $potentialChatPartners,
                    errorMessage: $errorMessage,
                    chats: $chats,
                    navigateToChat: $navigateToChat
                )
                .tabItem {
                    Label("Mehr", systemImage: "ellipsis")
                        .environment(\.symbolVariants, selectedTab == "more" ? .fill : .none)
                }
                .tag("more")
            }
            .toolbar {
                // Zeige das "+" nur in der jeweiligen Ansicht
                if selectedTab == "workflow" {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            transferProcessViewModel.showingNewProcess = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
                if selectedTab == "chats" {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            print("New Chat Button Tapped - Showing Sheet")
                            showingNewChatSheet = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewChatSheet) {
                NewChatView(
                    potentialChatPartners: potentialChatPartners,
                    selectedPartner: $selectedPartner,
                    onCreate: { partnerID in
                        guard let userID = authManager.userID else {
                            errorMessage = "Benutzer-ID nicht verfügbar."
                            return
                        }
                        Task {
                            do {
                                print("Creating Chat with Participants: \(userID), \(partnerID)")
                                let chatID = try await FirestoreManager.shared.createChat(participantIDs: [userID, partnerID])
                                print("Chat Created with ID: \(chatID)")
                                // Lade den neuen Chat
                                let newChat = Chat(
                                    id: chatID,
                                    participantIDs: [userID, partnerID],
                                    lastMessage: nil,
                                    lastMessageTimestamp: Date()
                                )
                                // Schließe die Sheet-Ansicht
                                showingNewChatSheet = false
                                // Navigiere direkt zum neuen Chat
                                await MainActor.run {
                                    navigateToChat = newChat
                                }
                            } catch {
                                errorMessage = "Fehler beim Erstellen des Chats: \(error.localizedDescription)"
                                print("Error Creating Chat: \(error)")
                            }
                        }
                    },
                    onCancel: {
                        showingNewChatSheet = false
                        selectedPartner = nil
                    }
                )
            }
            .navigationDestination(isPresented: Binding(
                get: { navigateToChat != nil },
                set: { if !$0 { navigateToChat = nil } }
            )) {
                if let chat = navigateToChat {
                    ChatDetailView(chat: chat, onChatUpdated: {
                        Task {
                            await loadChats()
                        }
                    })
                    .environmentObject(authManager)
                }
            }
            .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                print("EmployeeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
                updateClientsWithUserID()
                loadPotentialChatPartners()
                Task {
                    await loadChats()
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

    private func loadChats() async {
        guard let userID = authManager.userID else {
            errorMessage = "Benutzer-ID nicht verfügbar."
            return
        }
        do {
            let loadedChats = try await FirestoreManager.shared.getChats(forUserID: userID)
            await MainActor.run {
                chats = loadedChats
                print("Loaded Chats in EmployeeView: \(loadedChats.count)")
            }
        } catch {
            errorMessage = "Fehler beim Laden der Chats: \(error.localizedDescription)"
        }
    }

    private func loadPotentialChatPartners() {
        guard let userID = authManager.userID else {
            errorMessage = "Benutzer-ID nicht verfügbar."
            return
        }
        Task {
            do {
                // Lade alle Benutzer aus der "users"-Collection
                let userSnapshot = try await Firestore.firestore().collection("users").getDocuments()
                let users = userSnapshot.documents.compactMap { doc -> (id: String, name: String)? in
                    let data = doc.data()
                    let vorname = data["vorname"] as? String ?? "Unbekannt"
                    let name = data["name"] as? String ?? "Unbekannt"
                    let globalID = data["globalID"] as? String ?? doc.documentID
                    print("User: \(globalID), Name: \(vorname) \(name)")
                    return (id: globalID, name: "\(vorname) \(name)")
                }
                print("Loaded Users: \(users)")

                // Lade alle Klienten aus der "clients"-Collection
                let clientSnapshot = try await Firestore.firestore().collection("clients").getDocuments()
                let clients = clientSnapshot.documents.compactMap { doc -> (id: String, name: String)? in
                    let data = doc.data()
                    let vorname = data["vorname"] as? String ?? "Unbekannt"
                    let name = data["name"] as? String ?? "Unbekannt"
                    let globalID = data["globalID"] as? String ?? doc.documentID
                    print("Client: \(globalID), Name: \(vorname) \(name)")
                    return (id: globalID, name: "\(vorname) \(name)")
                }
                print("Loaded Clients: \(clients)")

                // Lade alle Funktionäre aus der "funktionare"-Collection
                let funktionarSnapshot = try await Firestore.firestore().collection("funktionare").getDocuments()
                let funktionare = funktionarSnapshot.documents.compactMap { doc -> (id: String, name: String)? in
                    let data = doc.data()
                    let vorname = data["vorname"] as? String ?? "Unbekannt"
                    let name = data["name"] as? String ?? "Unbekannt"
                    let globalID = data["globalID"] as? String ?? doc.documentID
                    print("Funktionär: \(globalID), Name: \(vorname) \(name)")
                    return (id: globalID, name: "\(vorname) \(name)")
                }
                print("Loaded Funktionäre: \(funktionare)")

                // Kombiniere alle Entitäten in einer Liste
                var potentialPartners: [(id: String, name: String)] = []
                potentialPartners.append(contentsOf: users)
                potentialPartners.append(contentsOf: clients)
                potentialPartners.append(contentsOf: funktionare)

                // Entferne Duplikate basierend auf der globalID
                var seenIDs: Set<String> = []
                potentialPartners = potentialPartners.filter { partner in
                    if seenIDs.contains(partner.id) {
                        return false
                    }
                    seenIDs.insert(partner.id)
                    return true
                }
                print("Combined Potential Chat Partners: \(potentialPartners)")

                // Entferne den aktuellen Benutzer aus der Liste
                let filteredPartners = potentialPartners.filter { partner in
                    partner.id != userID
                }
                print("Filtered Potential Chat Partners: \(filteredPartners)")

                await MainActor.run {
                    potentialChatPartners = filteredPartners
                }
            } catch {
                errorMessage = "Fehler beim Laden der Chat-Partner: \(error.localizedDescription)"
            }
        }
    }
}

// Neue MoreView für das "..."-Menü
struct MoreView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingNewChatSheet: Bool
    @Binding var selectedPartner: String?
    @Binding var potentialChatPartners: [(id: String, name: String)]
    @Binding var errorMessage: String
    @Binding var chats: [Chat]
    @Binding var navigateToChat: Chat?

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    NavigationLink(destination: SponsorListView().environmentObject(authManager)) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(accentColor)
                            Text("Sponsoren")
                                .foregroundColor(textColor)
                        }
                    }
                    .listRowBackground(cardBackgroundColor)

                    NavigationLink(destination: ContractListView().environmentObject(authManager)) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(accentColor)
                            Text("Verträge")
                                .foregroundColor(textColor)
                        }
                    }
                    .listRowBackground(cardBackgroundColor)

                    NavigationLink(destination: MatchListView().environmentObject(authManager)) {
                        HStack {
                            Image(systemName: "sportscourt")
                                .foregroundColor(accentColor)
                            Text("Spiele")
                                .foregroundColor(textColor)
                        }
                    }
                    .listRowBackground(cardBackgroundColor)

                    NavigationLink(destination: UserSettingsView(isPresented: .constant(true)).environmentObject(authManager)) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(accentColor)
                            Text("Einstellungen")
                                .foregroundColor(textColor)
                        }
                    }
                    .listRowBackground(cardBackgroundColor)
                }
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
            }
            .navigationTitle("Mehr")
            .foregroundColor(textColor)
        }
    }
}

#Preview {
    EmployeeView()
        .environmentObject(AuthManager())
        .environmentObject(TransferProcessViewModel(authManager: AuthManager()))
}
