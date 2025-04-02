//
//  ClientHomeView.swift

import SwiftUI
import FirebaseFirestore

struct ClientHomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var transferProcessViewModel: TransferProcessViewModel
    @State private var showingNewChatSheet = false
    @State private var selectedPartner: String? = nil
    @State private var potentialChatPartners: [(id: String, name: String)] = []
    @State private var errorMessage: String = ""
    @State private var chats: [Chat] = []
    @State private var navigateToChat: Chat? = nil // Für die Navigation zum neuen Chat

    var body: some View {
        NavigationStack {
            TabView {
                Text("Client Home")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

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
                    }
                    .environmentObject(authManager)
            }
            .toolbar {
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
                print("ClientHomeView - Authentifiziert: \(authManager.isLoggedIn), UserRole: \(String(describing: authManager.userRole)), UserEmail: \(String(describing: authManager.userEmail))")
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
                print("Loaded Chats in ClientHomeView: \(loadedChats.count)")
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

#Preview {
    ClientHomeView()
        .environmentObject(AuthManager())
        .environmentObject(TransferProcessViewModel(authManager: AuthManager()))
}
