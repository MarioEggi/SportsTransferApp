import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    private init() {}

    func getClients(limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer-ID nicht verfügbar"])
        }
        let query = db.collection("clients")
            .whereField("userID", isEqualTo: userID)
            .order(by: "name")
            .limit(to: limit)
        let snapshot = try await query.getDocuments()
        let clients = snapshot.documents.compactMap { try? $0.data(as: Client.self) }
        let lastDocument = snapshot.documents.last // Dies ist ein QueryDocumentSnapshot
        return (clients, lastDocument)
    }

    func getClients(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer-ID nicht verfügbar"])
        }
        var query = db.collection("clients")
            .whereField("userID", isEqualTo: userID)
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let clients = snapshot.documents.compactMap { try? $0.data(as: Client.self) }
        let newLastDocument = snapshot.documents.last // Dies ist ein QueryDocumentSnapshot
        return (clients, newLastDocument)
    }

    func createClient(client: Client) async throws {
        let data = try Firestore.Encoder().encode(client)
        try await db.collection("clients").addDocument(data: data)
    }

    func updateClient(client: Client) async throws {
        guard let id = client.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client-ID nicht vorhanden"])
        }
        print("FirestoreManager - Client zum Aktualisieren: \(client)")
        let data = try Firestore.Encoder().encode(client)
        print("FirestoreManager - Encodierte Daten: \(data)")
        try await db.collection("clients").document(id).setData(data)
        print("FirestoreManager - Client erfolgreich in Firestore gespeichert")
    }

    func deleteClient(clientID: String) async throws {
        try await db.collection("clients").document(clientID).delete()
    }

    func getFunktionäre(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Funktionär], QueryDocumentSnapshot?) {
        var query = db.collection("funktionare")
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let funktionäre = snapshot.documents.compactMap { try? $0.data(as: Funktionär.self) }
        let newLastDocument = snapshot.documents.last // QueryDocumentSnapshot
        return (funktionäre, newLastDocument)
    }

    func createFunktionär(funktionär: Funktionär) async throws {
        let data = try Firestore.Encoder().encode(funktionär)
        try await db.collection("funktionare").addDocument(data: data)
    }

    func updateFunktionär(funktionär: Funktionär) async throws {
        guard let id = funktionär.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Funktionär-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(funktionär)
        try await db.collection("funktionare").document(id).setData(data)
    }

    func deleteFunktionär(funktionärID: String) async throws {
        try await db.collection("funktionare").document(funktionärID).delete()
    }

    func getClubs(limit: Int) async throws -> ([Club], QueryDocumentSnapshot?) {
        let query = db.collection("clubs")
            .order(by: "name")
            .limit(to: limit)
        let snapshot = try await query.getDocuments()
        let clubs = snapshot.documents.compactMap { try? $0.data(as: Club.self) }
        let lastDocument = snapshot.documents.last
        return (clubs, lastDocument)
    }

    func getClubs(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Club], QueryDocumentSnapshot?) {
        var query = db.collection("clubs")
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let clubs = snapshot.documents.compactMap { try? $0.data(as: Club.self) }
        let newLastDocument = snapshot.documents.last
        return (clubs, newLastDocument)
    }

    func createClub(club: Club) async throws {
        let data = try Firestore.Encoder().encode(club)
        try await db.collection("clubs").addDocument(data: data)
    }

    func updateClub(club: Club) async throws {
        guard let id = club.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Club-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(club)
        try await db.collection("clubs").document(id).setData(data)
    }

    func deleteClub(clubID: String) async throws {
        try await db.collection("clubs").document(clubID).delete()
    }

    func getContracts(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Contract], QueryDocumentSnapshot?) {
        var query = db.collection("contracts")
            .order(by: "endDatum")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let contracts = snapshot.documents.compactMap { try? $0.data(as: Contract.self) }
        let newLastDocument = snapshot.documents.last
        return (contracts, newLastDocument)
    }

    func createContract(contract: Contract) async throws {
        let data = try Firestore.Encoder().encode(contract)
        try await db.collection("contracts").addDocument(data: data)
    }

    func updateContract(contract: Contract) async throws {
        guard let id = contract.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Contract-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(contract)
        try await db.collection("contracts").document(id).setData(data)
    }

    func deleteContract(contractID: String) async throws {
        try await db.collection("contracts").document(contractID).delete()
    }

    func getTransfers(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Transfer], QueryDocumentSnapshot?) {
            var query = db.collection("transfers")
                .order(by: "datum")
                .limit(to: limit)
            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }
            let snapshot = try await query.getDocuments()
            let transfers = snapshot.documents.compactMap { try? $0.data(as: Transfer.self) }
            let newLastDocument = snapshot.documents.last // QueryDocumentSnapshot
            return (transfers, newLastDocument)
        }

    func createTransfer(transfer: Transfer) async throws {
        let data = try Firestore.Encoder().encode(transfer)
        try await db.collection("transfers").addDocument(data: data)
    }

    func updateTransfer(transfer: Transfer) async throws {
        guard let id = transfer.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transfer-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(transfer)
        try await db.collection("transfers").document(id).setData(data)
    }

    func deleteTransfer(transferID: String) async throws {
        try await db.collection("transfers").document(transferID).delete()
    }

    func getMatches(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Match], QueryDocumentSnapshot?) {
        var query = db.collection("matches")
            .order(by: "datum")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let matches = snapshot.documents.compactMap { try? $0.data(as: Match.self) }
        let newLastDocument = snapshot.documents.last
        return (matches, newLastDocument)
    }

    func createMatch(match: Match) async throws {
        let data = try Firestore.Encoder().encode(match)
        try await db.collection("matches").addDocument(data: data)
    }

    func updateMatch(match: Match) async throws {
        guard let id = match.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Match-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(match)
        try await db.collection("matches").document(id).setData(data)
    }

    func deleteMatch(matchID: String) async throws {
        try await db.collection("matches").document(matchID).delete()
    }

    func getSponsors(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Sponsor], QueryDocumentSnapshot?) {
        var query = db.collection("sponsors")
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let sponsors = snapshot.documents.compactMap { try? $0.data(as: Sponsor.self) }
        let newLastDocument = snapshot.documents.last
        return (sponsors, newLastDocument)
    }

    func createSponsor(sponsor: Sponsor) async throws {
        let data = try Firestore.Encoder().encode(sponsor)
        try await db.collection("sponsors").addDocument(data: data)
    }

    func updateSponsor(sponsor: Sponsor) async throws {
        guard let id = sponsor.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sponsor-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(sponsor)
        try await db.collection("sponsors").document(id).setData(data)
    }

    func deleteSponsor(sponsorID: String) async throws {
        try await db.collection("sponsors").document(sponsorID).delete()
    }

    func getActivities(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Activity], QueryDocumentSnapshot?) {
        var query = db.collection("activities")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let activities = snapshot.documents.compactMap { try? $0.data(as: Activity.self) }
        let newLastDocument = snapshot.documents.last
        return (activities, newLastDocument)
    }

    func getActivities(forClientID clientID: String, limit: Int = 1000) async throws -> [Activity] {
        let snapshot = try await db.collection("activities")
            .whereField("clientID", isEqualTo: clientID)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Activity.self) }
    }

    func createActivity(activity: Activity) async throws {
        let data = try Firestore.Encoder().encode(activity)
        try await db.collection("activities").addDocument(data: data)
    }

    func updateActivity(activity: Activity) async throws {
        guard let id = activity.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Activity-ID nicht vorhanden"])
        }
        let data = try Firestore.Encoder().encode(activity)
        try await db.collection("activities").document(id).setData(data)
    }

    func deleteActivity(activityID: String) async throws {
        try await db.collection("activities").document(activityID).delete()
    }

    func uploadImage(documentID: String, image: UIImage, collection: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Konvertieren des Bildes"])
        }
        let storageRef = Storage.storage().reference().child("\(collection)/\(documentID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    func getChats(forUserID userID: String) async throws -> [Chat] {
        let snapshot = try await db.collection("chats")
            .whereField("participantIDs", arrayContains: userID)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Chat.self) }
    }

    func getMessages(forChatID chatID: String, limit: Int = 50) async throws -> [Message] {
        let snapshot = try await db.collection("chats").document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Message.self) }
    }

    func sendMessage(_ message: Message, inChatID chatID: String) async throws {
        let data = try Firestore.Encoder().encode(message)
        try await db.collection("chats").document(chatID)
            .collection("messages")
            .addDocument(data: data)
        try await db.collection("chats").document(chatID).updateData([
            "lastMessage": message.content ?? "",
            "lastMessageTimestamp": message.timestamp
        ])
    }

    func updateClientsWithUserID(userID: String) async throws {
        let snapshot = try await db.collection("clients")
            .whereField("userID", isEqualTo: NSNull())
            .getDocuments()
        let batch = db.batch()
        for document in snapshot.documents {
            let ref = db.collection("clients").document(document.documentID)
            batch.updateData(["userID": userID], forDocument: ref)
        }
        try await batch.commit()
    }
}
