import Foundation
import FirebaseFirestore
import FirebaseStorage

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Klienten-Methoden
    func getClients() async throws -> [Client] {
        let snapshot = try await db.collection("clients").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Client.self) }
    }

    func createClient(client: Client) async throws {
        try await db.collection("clients").addDocument(from: client)
    }

    func updateClient(client: Client) async throws {
        guard let id = client.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Client-ID verfügbar"])
        }
        try await db.collection("clients").document(id).setData(from: client)
    }

    func deleteClient(clientID: String) async throws {
        try await db.collection("clients").document(clientID).delete()
    }

    // MARK: - Funktionär-Methoden
    func getFunktionäre() async throws -> [Funktionär] {
        let snapshot = try await db.collection("funktionare").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Funktionär.self) }
    }

    func createFunktionär(funktionär: Funktionär) async throws {
        try await db.collection("funktionare").addDocument(from: funktionär)
    }

    func updateFunktionär(funktionär: Funktionär) async throws {
        guard let id = funktionär.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Funktionär-ID verfügbar"])
        }
        try await db.collection("funktionare").document(id).setData(from: funktionär)
    }

    func deleteFunktionär(funktionärID: String) async throws {
        try await db.collection("funktionare").document(funktionärID).delete()
    }

    // MARK: - Vereins-Methoden
    func getClubs() async throws -> [Club] {
        let snapshot = try await db.collection("clubs").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Club.self) }
    }

    func createClub(club: Club) async throws {
        try await db.collection("clubs").addDocument(from: club)
    }

    func updateClub(club: Club) async throws {
        guard let id = club.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Club-ID verfügbar"])
        }
        try await db.collection("clubs").document(id).setData(from: club)
    }

    func deleteClub(clubID: String) async throws {
        try await db.collection("clubs").document(clubID).delete()
    }

    // MARK: - Vertrag-Methoden
    func getContracts() async throws -> [Contract] {
        let snapshot = try await db.collection("contracts").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Contract.self) }
    }

    func getContract(forClientID clientID: String) async throws -> Contract? {
        let snapshot = try await db.collection("contracts")
            .whereField("clientID", isEqualTo: clientID)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { try? $0.data(as: Contract.self) }
    }

    func createContract(contract: Contract) async throws {
        try await db.collection("contracts").addDocument(from: contract)
    }

    func updateContract(contract: Contract) async throws {
        guard let id = contract.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Contract-ID verfügbar"])
        }
        try await db.collection("contracts").document(id).setData(from: contract)
    }

    func deleteContract(contractID: String) async throws {
        try await db.collection("contracts").document(contractID).delete()
    }

    // MARK: - Transfer-Methoden
    func getTransfers() async throws -> [Transfer] {
        let snapshot = try await db.collection("transfers").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Transfer.self) }
    }

    func createTransfer(transfer: Transfer) async throws {
        try await db.collection("transfers").addDocument(from: transfer)
    }

    func updateTransfer(transfer: Transfer) async throws {
        guard let id = transfer.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Transfer-ID verfügbar"])
        }
        try await db.collection("transfers").document(id).setData(from: transfer)
    }

    func deleteTransfer(transferID: String) async throws {
        try await db.collection("transfers").document(transferID).delete()
    }

    // MARK: - Match-Methoden
    func getMatches() async throws -> [Match] {
        let snapshot = try await db.collection("matches").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Match.self) }
    }

    func createMatch(match: Match) async throws {
        try await db.collection("matches").addDocument(from: match)
    }

    func updateMatch(match: Match) async throws {
        guard let id = match.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Match-ID verfügbar"])
        }
        try await db.collection("matches").document(id).setData(from: match)
    }

    func deleteMatch(matchID: String) async throws {
        try await db.collection("matches").document(matchID).delete()
    }

    // MARK: - Sponsor-Methoden
    func getSponsors() async throws -> [Sponsor] {
        let snapshot = try await db.collection("sponsors").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Sponsor.self) }
    }

    func createSponsor(sponsor: Sponsor) async throws {
        try await db.collection("sponsors").addDocument(from: sponsor)
    }

    func updateSponsor(sponsor: Sponsor) async throws {
        guard let id = sponsor.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Sponsor-ID verfügbar"])
        }
        try await db.collection("sponsors").document(id).setData(from: sponsor)
    }

    func deleteSponsor(sponsorID: String) async throws {
        try await db.collection("sponsors").document(sponsorID).delete()
    }

    // MARK: - Profilbild-Methoden
    func uploadProfileImage(documentID: String, image: UIImage, collection: String = "profile_images") async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bild konnte nicht komprimiert werden"])
        }

        let storageRef = storage.reference().child("\(collection)/\(documentID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    // MARK: - Aktivitäten-Methoden
    func createActivity(activity: Activity) async throws {
        try await db.collection("activities").addDocument(from: activity)
    }

    func getActivities(forClientID clientID: String) async throws -> [Activity] {
        let snapshot = try await db.collection("activities")
            .whereField("clientID", isEqualTo: clientID)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Activity.self) }
    }

    func updateActivity(activity: Activity) async throws {
        guard let id = activity.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kein Activity-ID verfügbar"])
        }
        try await db.collection("activities").document(id).setData(from: activity)
    }

    func deleteActivity(activityID: String) async throws {
        try await db.collection("activities").document(activityID).delete()
    }

    // MARK: - Chat-Methoden
    func createOrUpdateChat(chat: Chat) async throws -> String {
        let ref: DocumentReference
        if let id = chat.id {
            ref = db.collection("chats").document(id)
        } else {
            ref = db.collection("chats").document()
        }
        try await ref.setData(from: chat)
        return ref.documentID
    }

    func sendMessage(chatID: String, message: Message) async throws {
        let chatRef = db.collection("chats").document(chatID)
        let messagesRef = chatRef.collection("messages").document()
        try await messagesRef.setData(from: message)
        try await chatRef.updateData([
            "lastMessage": message.content,
            "lastMessageTimestamp": message.timestamp
        ])
    }

    func getChats(forUserID userID: String) async throws -> [Chat] {
        let snapshot = try await db.collection("chats")
            .whereField("participantIDs", arrayContains: userID)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Chat.self) }
    }

    func getMessages(forChatID chatID: String) async throws -> [Message] {
        let snapshot = try await db.collection("chats").document(chatID).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Message.self) }
    }
}
