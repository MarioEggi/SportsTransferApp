import SwiftUI
import FirebaseFirestore

struct ChatListView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showingNewChatSheet: Bool
    @Binding var selectedPartner: String?
    @Binding var potentialChatPartners: [(id: String, name: String)]
    @Binding var errorMessage: String
    @Binding var chats: [Chat]
    let onChatCreated: (Chat) -> Void

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
                VStack(spacing: 0) {
                    HStack {
                        Text("Chats")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: { showingNewChatSheet = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if chats.isEmpty {
                            Text("Keine Chats vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
                            ForEach(chats) { chat in
                                NavigationLink(destination: ChatDetailView(chat: chat, onChatUpdated: {
                                    Task { await loadChats() }
                                })) {
                                    ChatRow(chat: chat)
                                        .padding(.vertical, 8)
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(cardBackgroundColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                        .padding(.vertical, 2)
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showingNewChatSheet) {
                    NewChatView(
                        potentialChatPartners: potentialChatPartners,
                        selectedPartner: $selectedPartner,
                        onCreate: { partnerID in
                            Task {
                                do {
                                    let chatID = try await FirestoreManager.shared.createChat(participantIDs: [authManager.userID!, partnerID])
                                    let chatDoc = try await Firestore.firestore().collection("chats").document(chatID).getDocument()
                                    guard var newChat = try? chatDoc.data(as: Chat.self) else {
                                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat konnte nicht geladen werden"])
                                    }
                                    newChat.id = chatID // Stelle sicher, dass die ID gesetzt ist
                                    onChatCreated(newChat)
                                    await loadChats()
                                    showingNewChatSheet = false
                                } catch {
                                    errorMessage = "Fehler beim Erstellen des Chats: \(error.localizedDescription)"
                                }
                            }
                        },
                        onCancel: { showingNewChatSheet = false }
                    )
                }
                .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor))
                    )
                }
                .task {
                    await loadChats()
                }
            }
        }
    }

    private func ChatRow(chat: Chat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "message.fill")
                .foregroundColor(accentColor)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(getChatPartnerName(chat: chat))
                    .font(.headline)
                    .foregroundColor(textColor)
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage)
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let timestamp = chat.lastMessageTimestamp {
                Text(dateFormatter.string(from: timestamp))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func getChatPartnerName(chat: Chat) -> String {
        guard let userID = authManager.userID else { return "Unbekannt" }
        let partnerID = chat.participantIDs.first { $0 != userID } ?? "Unbekannt"
        if let partner = potentialChatPartners.first(where: { $0.id == partnerID }) {
            return partner.name
        }
        return partnerID
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
            }
        } catch {
            errorMessage = "Fehler beim Laden der Chats: \(error.localizedDescription)"
        }
    }
}

struct NewChatView: View {
    let potentialChatPartners: [(id: String, name: String)]
    @Binding var selectedPartner: String?
    let onCreate: (String) -> Void
    let onCancel: () -> Void

    // Farben für das helle Design (für diese View, da sie als Sheet dient)
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    Section(header: Text("Neuen Chat starten").foregroundColor(textColor)) {
                        VStack(spacing: 10) {
                            if potentialChatPartners.isEmpty {
                                Text("Keine Chat-Partner verfügbar.")
                                    .foregroundColor(secondaryTextColor)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                            } else {
                                Picker("Chat-Partner", selection: $selectedPartner) {
                                    Text("Partner auswählen").tag(String?.none)
                                    ForEach(potentialChatPartners, id: \.id) { partner in
                                        Text(partner.name).tag(partner.id as String?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .foregroundColor(textColor)
                                .tint(accentColor)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.vertical, 2)
                    )
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .navigationTitle("Neuer Chat")
                .foregroundColor(textColor)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { onCancel() }
                            .foregroundColor(accentColor)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Erstellen") {
                            if let partner = selectedPartner {
                                onCreate(partner)
                            }
                        }
                        .disabled(selectedPartner == nil)
                        .foregroundColor(accentColor)
                    }
                }
            }
        }
    }
}

#Preview {
    ChatListView(
        showingNewChatSheet: .constant(false),
        selectedPartner: .constant(nil),
        potentialChatPartners: .constant([]),
        errorMessage: .constant(""),
        chats: .constant([]),
        onChatCreated: { _ in }
    )
    .environmentObject(AuthManager())
}
