import SwiftUI
import FirebaseFirestore

struct ChatDetailView: View {
    let chat: Chat
    let onChatUpdated: () -> Void
    @EnvironmentObject var authManager: AuthManager
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var errorMessage: String = ""
    @State private var partnerName: String = "Chat"

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")
    private let textFieldBackgroundColor = Color(hex: "#D1D5DB")

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                    }
                }
                .padding()
            }

            // Eingabefeld für neue Nachricht
            HStack {
                TextField("Nachricht eingeben...", text: $newMessage)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(textColor)
                    .padding(10)
                    .background(textFieldBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newMessage.isEmpty ? secondaryTextColor : accentColor)
                        .font(.system(size: 20))
                }
                .disabled(newMessage.isEmpty)
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            .background(cardBackgroundColor)
        }
        .navigationTitle(partnerName)
        .navigationBarTitleDisplayMode(.inline)
        .foregroundColor(textColor)
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .task {
            await loadPartnerName()
            await loadMessages()
        }
        .alert(isPresented: Binding(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
            Alert(
                title: Text("Fehler").foregroundColor(textColor),
                message: Text(errorMessage).foregroundColor(secondaryTextColor),
                dismissButton: .default(Text("OK").foregroundColor(accentColor))
            )
        }
    }

    private func MessageRow(message: ChatMessage) -> some View {
        let isCurrentUser = message.senderID == authManager.userID
        return HStack {
            if isCurrentUser { Spacer() }
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content ?? "")
                    .foregroundColor(textColor)
                    .padding(10)
                    .background(isCurrentUser ? accentColor : cardBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(dateFormatter.string(from: message.timestamp))
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func loadPartnerName() async {
        guard let userID = authManager.userID else {
            errorMessage = "Benutzer-ID nicht verfügbar."
            return
        }
        let partnerID = chat.participantIDs.first { $0 != userID } ?? "Unbekannt"
        
        do {
            let userDoc = try await Firestore.firestore().collection("users").document(partnerID).getDocument()
            if userDoc.exists, let userData = userDoc.data() {
                if let vorname = userData["vorname"] as? String,
                   let name = userData["name"] as? String {
                    await MainActor.run { partnerName = "\(vorname) \(name)" }
                    return
                }
            }

            let clientSnapshot = try await Firestore.firestore().collection("clients")
                .whereField("globalID", isEqualTo: partnerID)
                .getDocuments()
            if !clientSnapshot.documents.isEmpty, let clientData = clientSnapshot.documents.first?.data() {
                if let vorname = clientData["vorname"] as? String,
                   let name = clientData["name"] as? String {
                    await MainActor.run { partnerName = "\(vorname) \(name)" }
                    return
                }
            }

            let funktionarSnapshot = try await Firestore.firestore().collection("funktionare")
                .whereField("globalID", isEqualTo: partnerID)
                .getDocuments()
            if !funktionarSnapshot.documents.isEmpty, let funktionarData = funktionarSnapshot.documents.first?.data() {
                if let vorname = funktionarData["vorname"] as? String,
                   let name = funktionarData["name"] as? String {
                    await MainActor.run { partnerName = "\(vorname) \(name)" }
                    return
                }
            }

            await MainActor.run { partnerName = "Unbekannt" }
        } catch {
            errorMessage = "Fehler beim Laden des Partnernamens: \(error.localizedDescription)"
        }
    }

    private func loadMessages() async {
        do {
            let loadedMessages = try await FirestoreManager.shared.getMessages(forChatID: chat.id ?? "")
            await MainActor.run { messages = loadedMessages }
        } catch {
            errorMessage = "Fehler beim Laden der Nachrichten: \(error.localizedDescription)"
        }
    }

    private func sendMessage() {
        guard let userID = authManager.userID else {
            errorMessage = "Benutzer-ID nicht verfügbar."
            return
        }
        guard let userEmail = authManager.userEmail else {
            errorMessage = "Benutzer-E-Mail nicht verfügbar."
            return
        }
        guard let chatID = chat.id else {
            errorMessage = "Chat-ID nicht verfügbar."
            return
        }
        let message = ChatMessage(
            id: UUID().uuidString,
            senderID: userID,
            senderEmail: userEmail,
            content: newMessage,
            fileURL: nil,
            fileType: nil,
            timestamp: Date(),
            readBy: [userID]
        )
        Task {
            do {
                try await FirestoreManager.shared.sendMessage(message, inChatID: chatID)
                await loadMessages()
                await MainActor.run {
                    newMessage = ""
                    onChatUpdated()
                }
            } catch {
                errorMessage = "Fehler beim Senden der Nachricht: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ChatDetailView(chat: Chat(
        id: "1",
        participantIDs: ["user1", "user2"],
        lastMessage: "Hallo!",
        lastMessageTimestamp: Date()
    ), onChatUpdated: {})
    .environmentObject(AuthManager())
}
