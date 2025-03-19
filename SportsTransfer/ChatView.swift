import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var chats: [Chat] = []
    @State private var selectedChat: Chat? = nil
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            if selectedChat == nil {
                List {
                    ForEach(chats) { chat in
                        Button(action: {
                            selectedChat = chat
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(chatParticipants(chat))
                                        .font(.headline)
                                    if let lastMessage = chat.lastMessage {
                                        Text(lastMessage)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if let timestamp = chat.lastMessageTimestamp {
                                    Text(timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .navigationTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            startNewChat()
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            } else {
                ChatDetailView(chat: selectedChat!, onBack: {
                    selectedChat = nil
                })
            }
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .task {
            await loadChats()
        }
    }
    
    private func chatParticipants(_ chat: Chat) -> String {
        guard let userID = authManager.userID else { return "Unbekannt" }
        let otherParticipants = chat.participantIDs.filter { $0 != userID }
        return otherParticipants.joined(separator: ", ")
    }
    
    private func loadChats() async {
        guard let userID = authManager.userID else {
            await MainActor.run {
                errorMessage = "Nicht angemeldet"
            }
            return
        }
        do {
            let loadedChats = try await FirestoreManager.shared.getChats(forUserID: userID)
            await MainActor.run {
                chats = loadedChats
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Chats: \(error.localizedDescription)"
            }
        }
    }
    
    private func startNewChat() {
        guard let userID = authManager.userID, let userEmail = authManager.userEmail else { return }
        let newChat = Chat(participantIDs: [userID, "test_user"], lastMessage: nil, lastMessageTimestamp: nil)
        Task {
            do {
                let chatID = try await FirestoreManager.shared.createOrUpdateChat(chat: newChat)
                await MainActor.run {
                    chats.append(Chat(id: chatID, participantIDs: newChat.participantIDs, lastMessage: nil, lastMessageTimestamp: nil))
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Fehler beim Erstellen des Chats: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ChatDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let chat: Chat
    let onBack: () -> Void
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        HStack {
                            if message.senderID == authManager.userID {
                                Spacer()
                                Text(message.content)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                            } else {
                                Text(message.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.black)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            HStack {
                TextField("Nachricht eingeben...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.send)
                    .onSubmit {
                        Task {
                            await sendMessage()
                        }
                    }
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle(chatParticipants(chat))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Zurück") { onBack() }
            }
        }
        .alert(isPresented: .constant(!errorMessage.isEmpty)) {
            Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                errorMessage = ""
            })
        }
        .task {
            await loadMessages()
        }
    }
    
    private func chatParticipants(_ chat: Chat) -> String {
        guard let userID = authManager.userID else { return "Unbekannt" }
        let otherParticipants = chat.participantIDs.filter { $0 != userID }
        return otherParticipants.joined(separator: ", ")
    }
    
    private func loadMessages() async {
        guard let chatID = chat.id else {
            await MainActor.run {
                errorMessage = "Keine Chat-ID verfügbar"
            }
            return
        }
        do {
            let loadedMessages = try await FirestoreManager.shared.getMessages(forChatID: chatID)
            await MainActor.run {
                messages = loadedMessages
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Nachrichten: \(error.localizedDescription)"
            }
        }
    }
    
    private func sendMessage() async {
        guard let userID = authManager.userID, let userEmail = authManager.userEmail, let chatID = chat.id else {
            await MainActor.run {
                errorMessage = "Nicht angemeldet oder keine Chat-ID"
            }
            return
        }
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let message = Message(senderID: userID, senderEmail: userEmail, content: newMessage, timestamp: Date())
        do {
            try await FirestoreManager.shared.sendMessage(chatID: chatID, message: message)
            await MainActor.run {
                newMessage = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Senden der Nachricht: \(error.localizedDescription)"
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let count: Int
    let icon: String

    var body: some View {
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
        }
        .frame(width: 80, height: 80)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    ChatView()
        .environmentObject(AuthManager())
}
