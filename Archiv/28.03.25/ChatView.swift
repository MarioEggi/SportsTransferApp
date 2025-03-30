import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var chats: [Chat] = []
    @State private var selectedChat: Chat?
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var errorMessage: String = ""
    @State private var errorQueue: [String] = []
    @State private var isShowingError = false
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                if authManager.userRole == .gast {
                    Text("Bitte melde dich an, um den Chat zu nutzen.")
                        .foregroundColor(.gray)
                        .padding()
                } else if chats.isEmpty {
                    Text("Keine Chats vorhanden.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(chats) { chat in
                        NavigationLink(
                            destination: ChatDetailView(
                                chat: chat,
                                messages: $messages,
                                newMessage: $newMessage,
                                sendMessage: { chatID in
                                    await sendMessage(chatID: chatID)
                                }
                            ),
                            tag: chat,
                            selection: $selectedChat
                        ) {
                            ChatRow(chat: chat)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .task {
                await loadChats()
            }
            .alert(isPresented: $isShowingError) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
                        if !errorQueue.isEmpty {
                            errorMessage = errorQueue.removeFirst()
                            isShowingError = true
                        } else {
                            isShowingError = false
                        }
                    }
                )
            }
        }
    }

    private func loadChats() async {
        guard let userID = authManager.userID else {
            addErrorToQueue("Nicht angemeldet")
            return
        }
        await MainActor.run { isLoading = true }
        do {
            let loadedChats = try await FirestoreManager.shared.getChats(forUserID: userID)
            await MainActor.run {
                chats = loadedChats
                isLoading = false
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Chats: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    private func sendMessage(chatID: String) async {
        guard let userID = authManager.userID, let userEmail = authManager.userEmail else {
            addErrorToQueue("Nicht angemeldet")
            return
        }
        let message = Message(
            senderID: userID,
            senderEmail: userEmail,
            content: newMessage,
            fileURL: nil,
            fileType: nil,
            timestamp: Date(),
            readBy: [userID]
        )
        do {
            try await FirestoreManager.shared.sendMessage(message, inChatID: chatID)
            await MainActor.run {
                newMessage = ""
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Senden der Nachricht: \(error.localizedDescription)")
            }
        }
    }

    private func addErrorToQueue(_ message: String) {
        errorQueue.append(message)
        if !isShowingError {
            errorMessage = errorQueue.removeFirst()
            isShowingError = true
        }
    }
}

struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack {
            Image(systemName: "bubble.left")
                .foregroundColor(.blue)
            VStack(alignment: .leading) {
                Text(chat.participantIDs.joined(separator: ", "))
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

struct ChatDetailView: View {
    let chat: Chat
    @Binding var messages: [Message]
    @Binding var newMessage: String
    let sendMessage: (String) async -> Void

    var body: some View {
        VStack {
            List(messages) { message in
                MessageRow(message: message)
            }
            .task {
                await loadMessages()
            }

            HStack {
                TextField("Nachricht", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    Task {
                        await sendMessage(chat.id ?? "")
                        await loadMessages()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
    }

    private func loadMessages() async {
        guard let chatID = chat.id else { return }
        do {
            let loadedMessages = try await FirestoreManager.shared.getMessages(forChatID: chatID)
            await MainActor.run {
                messages = loadedMessages.reversed()
            }
        } catch {
            print("Fehler beim Laden der Nachrichten: \(error.localizedDescription)")
        }
    }
}

struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack {
            if message.senderID == Auth.auth().currentUser?.uid {
                Spacer()
                Text(message.content ?? "")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.content ?? "")
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    ChatView()
        .environmentObject(AuthManager())
}
