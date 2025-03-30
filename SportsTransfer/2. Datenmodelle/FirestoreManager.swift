import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    private init() {}

    func getAllClients(lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
        var query = db.collection("clients")
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let clients = snapshot.documents.compactMap { doc -> Client? in
            do {
                var client = try doc.data(as: Client.self)
                client.id = doc.documentID
                return client
            } catch {
                print("Fehler beim Dekodieren des Klienten \(doc.documentID): \(error)")
                return nil
            }
        }
        let lastDocument = snapshot.documents.last
        return (clients, lastDocument)
    }

    func getClients(forUserID userID: String, lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
        var query = db.collection("clients")
            .whereField("userID", isEqualTo: userID)
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let clients = snapshot.documents.compactMap { doc -> Client? in
            do {
                var client = try doc.data(as: Client.self)
                client.id = doc.documentID
                return client
            } catch {
                print("Fehler beim Dekodieren des Klienten \(doc.documentID): \(error)")
                return nil
            }
        }
        let lastDocument = snapshot.documents.last
        return (clients, lastDocument)
    }

    func getClients(lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer-ID nicht verfügbar"])
        }
        return try await getClients(forUserID: userID, lastDocument: lastDocument, limit: limit)
    }

    func createClient(client: Client) async throws -> String {
        do {
            let data = try Firestore.Encoder().encode(client)
            print("FirestoreManager - Client zum Erstellen: \(client)")
            print("FirestoreManager - Encodierte Daten: \(data)")
            let ref = try await db.collection("clients").addDocument(data: data)
            print("FirestoreManager - Client erfolgreich in Firestore erstellt mit ID: \(ref.documentID)")
            return ref.documentID
        } catch {
            print("FirestoreManager - Fehler beim Erstellen des Klienten: \(error)")
            throw error
        }
    }

    func updateClient(client: Client) async throws {
        guard let id = client.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client-ID nicht vorhanden"])
        }
        do {
            let data = try Firestore.Encoder().encode(client)
            print("FirestoreManager - Client zum Aktualisieren: \(client)")
            print("FirestoreManager - Encodierte Daten: \(data)")
            try await db.collection("clients").document(id).setData(data, merge: true)
            print("FirestoreManager - Client erfolgreich in Firestore aktualisiert")
        } catch {
            print("FirestoreManager - Fehler beim Aktualisieren des Klienten: \(error)")
            throw error
        }
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
        let newLastDocument = snapshot.documents.last
        return (funktionäre, newLastDocument)
    }

    func createFunktionär(funktionär: Funktionär) async throws -> String {
        let ref = Firestore.firestore().collection("funktionaere").document()
        try await ref.setData(from: funktionär)
        return ref.documentID
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

    func getMessages(forChatID chatID: String, limit: Int = 50) async throws -> [ChatMessage] { // Message zu ChatMessage geändert
        let snapshot = try await db.collection("chats").document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ChatMessage.self) }
    }

    func sendMessage(_ message: ChatMessage, inChatID chatID: String) async throws { // Message zu ChatMessage geändert
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

    func createTransferProcess(transferProcess: TransferProcess) async throws -> String {
        let ref = db.collection("transferProcesses").document()
        try await ref.setData(from: transferProcess)
        return ref.documentID
    }

    func getTransferProcesses(lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([TransferProcess], DocumentSnapshot?) {
        var query = db.collection("transferProcesses")
            .order(by: "startDatum", descending: true)
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let transferProcesses = snapshot.documents.compactMap { try? $0.data(as: TransferProcess.self) }
        let lastDoc = snapshot.documents.last
        return (transferProcesses, lastDoc)
    }

    func updateTransferProcess(transferProcess: TransferProcess) async throws {
        guard let id = transferProcess.id else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine ID vorhanden"]) }
        try await db.collection("transferProcesses").document(id).setData(from: transferProcess, merge: true)
    }

    func deleteTransferProcess(id: String) async throws {
        try await db.collection("transferProcesses").document(id).delete()
    }

    func uploadFile(documentID: String, data: Data, collection: String, fileName: String) async throws -> String {
        let storageRef = Storage.storage().reference().child("\(collection)/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
}
