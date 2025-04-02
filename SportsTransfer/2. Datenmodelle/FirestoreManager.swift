import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// Hilfsprotokoll für Typkonvertierung
private protocol AnyIdentifiable {
    var id: String? { get }
}

extension TransferProcess: AnyIdentifiable {}
extension SponsoringProcess: AnyIdentifiable {}
extension ProfileRequest: AnyIdentifiable {}

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    private init() {}

    func getClients(forGlobalID globalID: String, lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
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
                guard let clientGlobalID = client.globalID, clientGlobalID == globalID else {
                    print("Klient \(doc.documentID) hat kein passendes globalID: \(client.globalID ?? "nil")")
                    return nil
                }
                client.id = doc.documentID
                print("Geladener Klient (forGlobalID) - ID: \(client.id ?? "nil"), Name: \(client.vorname) \(client.name), GlobalID: \(client.globalID ?? "nil")")
                return client
            } catch {
                print("Fehler beim Dekodieren des Klienten \(doc.documentID): \(error)")
                print("Rohdaten des Dokuments: \(doc.data())")
                return nil
            }
        }
        let lastDocument = snapshot.documents.last
        print("Anzahl der geladenen Klienten (forGlobalID): \(clients.count)")
        return (clients, lastDocument)
    }

    func getClients(lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([Client], QueryDocumentSnapshot?) {
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
                guard client.globalID != nil else {
                    print("Klient \(doc.documentID) hat kein globalID.")
                    return nil
                }
                client.id = doc.documentID
                print("Geladener Klient - ID: \(client.id ?? "nil"), Name: \(client.vorname) \(client.name), GlobalID: \(client.globalID ?? "nil")")
                return client
            } catch {
                print("Fehler beim Dekodieren des Klienten \(doc.documentID): \(error)")
                print("Rohdaten des Dokuments: \(doc.data())")
                return nil
            }
        }
        let lastDocument = snapshot.documents.last
        print("Anzahl der geladenen Klienten: \(clients.count)")
        return (clients, lastDocument)
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
        let funktionäre = snapshot.documents.compactMap { doc -> Funktionär? in
            do {
                var funktionär = try doc.data(as: Funktionär.self)
                funktionär.id = doc.documentID
                return funktionär
            } catch {
                print("Fehler beim Dekodieren des Funktionärs \(doc.documentID): \(error)")
                return nil
            }
        }
        let newLastDocument = snapshot.documents.last
        return (funktionäre, newLastDocument)
    }

    func createFunktionär(funktionär: Funktionär) async throws -> String {
        let ref = db.collection("funktionare").document()
        try await ref.setData(from: funktionär)
        return ref.documentID
    }

    func updateFunktionär(funktionär: Funktionär) async throws {
        guard let id = funktionär.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Funktionär-ID nicht vorhanden"])
        }
        try await db.collection("funktionare").document(id).setData(from: funktionär)
    }

    func deleteFunktionär(funktionärID: String) async throws {
        try await db.collection("funktionare").document(funktionärID).delete()
    }

    func getClubs(lastDocument: DocumentSnapshot?, limit: Int) async throws -> ([Club], QueryDocumentSnapshot?) {
        var query = db.collection("clubs")
            .order(by: "name")
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let clubs = snapshot.documents.compactMap { doc -> Club? in
            do {
                var club = try doc.data(as: Club.self)
                club.id = doc.documentID
                return club
            } catch {
                print("Fehler beim Dekodieren des Clubs \(doc.documentID): \(error)")
                return nil
            }
        }
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
        try await db.collection("clubs").document(id).setData(from: club)
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
        let contracts = snapshot.documents.compactMap { doc -> Contract? in
            do {
                var contract = try doc.data(as: Contract.self)
                contract.id = doc.documentID
                return contract
            } catch {
                print("Fehler beim Dekodieren des Vertrags \(doc.documentID): \(error)")
                return nil
            }
        }
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
        try await db.collection("contracts").document(id).setData(from: contract)
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
        let matches = snapshot.documents.compactMap { doc -> Match? in
            do {
                var match = try doc.data(as: Match.self)
                match.id = doc.documentID
                return match
            } catch {
                print("Fehler beim Dekodieren des Spiels \(doc.documentID): \(error)")
                return nil
            }
        }
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
        try await db.collection("matches").document(id).setData(from: match)
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
        let sponsors = snapshot.documents.compactMap { doc -> Sponsor? in
            do {
                var sponsor = try doc.data(as: Sponsor.self)
                sponsor.id = doc.documentID
                return sponsor
            } catch {
                print("Fehler beim Dekodieren des Sponsors \(doc.documentID): \(error)")
                return nil
            }
        }
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
        try await db.collection("sponsors").document(id).setData(from: sponsor)
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
        let activities = snapshot.documents.compactMap { doc -> Activity? in
            do {
                var activity = try doc.data(as: Activity.self)
                activity.id = doc.documentID
                return activity
            } catch {
                print("Fehler beim Dekodieren der Aktivität \(doc.documentID): \(error)")
                return nil
            }
        }
        let newLastDocument = snapshot.documents.last
        return (activities, newLastDocument)
    }

    func getActivities(forClientID clientID: String, limit: Int = 1000) async throws -> [Activity] {
        let snapshot = try await db.collection("activities")
            .whereField("clientID", isEqualTo: clientID)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { doc -> Activity? in
            do {
                var activity = try doc.data(as: Activity.self)
                activity.id = doc.documentID
                return activity
            } catch {
                print("Fehler beim Dekodieren der Aktivität \(doc.documentID): \(error)")
                return nil
            }
        }
    }

    func createActivity(activity: Activity) async throws {
        let data = try Firestore.Encoder().encode(activity)
        try await db.collection("activities").addDocument(data: data)
    }

    func updateActivity(activity: Activity) async throws {
        guard let id = activity.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Activity-ID nicht vorhanden"])
        }
        try await db.collection("activities").document(id).setData(from: activity)
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
        print("Fetching chats for userID: \(userID)")
        let snapshot = try await db.collection("chats")
            .whereField("participantIDs", arrayContains: userID)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments()
        print("Fetched \(snapshot.documents.count) chat documents")
        let chats = snapshot.documents.compactMap { doc -> Chat? in
            do {
                var chat = try doc.data(as: Chat.self)
                chat.id = doc.documentID
                print("Decoded chat: \(chat)")
                return chat
            } catch {
                print("Fehler beim Dekodieren des Chats \(doc.documentID): \(error)")
                return nil
            }
        }
        print("Returning \(chats.count) chats")
        return chats
    }

    func createChat(participantIDs: [String], initialMessage: ChatMessage? = nil) async throws -> String {
        let chat = Chat(
            id: nil,
            participantIDs: participantIDs,
            lastMessage: initialMessage?.content,
            lastMessageTimestamp: initialMessage?.timestamp ?? Date()
        )
        let ref = db.collection("chats").document()
        try await ref.setData(from: chat)
        
        if let message = initialMessage {
            try await ref.collection("messages").document(message.id ?? UUID().uuidString).setData(from: message)
        }
        
        return ref.documentID
    }

    func getMessages(forChatID chatID: String, limit: Int = 50) async throws -> [ChatMessage] {
        print("Fetching messages for chatID: \(chatID)")
        let snapshot = try await db.collection("chats").document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        print("Fetched \(snapshot.documents.count) message documents")
        let messages = snapshot.documents.compactMap { doc -> ChatMessage? in
            do {
                let message = try doc.data(as: ChatMessage.self)
                print("Decoded message: \(message)")
                return message
            } catch {
                print("Fehler beim Dekodieren der Nachricht \(doc.documentID): \(error)")
                return nil
            }
        }
        return messages
    }

    func sendMessage(_ message: ChatMessage, inChatID chatID: String) async throws {
        let data = try Firestore.Encoder().encode(message)
        try await db.collection("chats").document(chatID)
            .collection("messages")
            .document(message.id ?? UUID().uuidString)
            .setData(data)
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
        let transferProcesses = snapshot.documents.compactMap { doc -> TransferProcess? in
            do {
                var process = try doc.data(as: TransferProcess.self)
                process.id = doc.documentID
                return process
            } catch {
                print("Fehler beim Dekodieren des Transferprozesses \(doc.documentID): \(error)")
                return nil
            }
        }
        let lastDoc = snapshot.documents.last
        return (transferProcesses, lastDoc)
    }

    func createSponsoringProcess(sponsoringProcess: SponsoringProcess) async throws -> String {
        let ref = db.collection("sponsoringProcesses").document()
        try await ref.setData(from: sponsoringProcess)
        return ref.documentID
    }

    func getSponsoringProcesses(lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([SponsoringProcess], DocumentSnapshot?) {
        var query = db.collection("sponsoringProcesses")
            .order(by: "startDatum", descending: true)
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let processes = snapshot.documents.compactMap { doc -> SponsoringProcess? in
            do {
                var process = try doc.data(as: SponsoringProcess.self)
                process.id = doc.documentID
                return process
            } catch {
                print("Fehler beim Dekodieren des Sponsoringprozesses \(doc.documentID): \(error)")
                return nil
            }
        }
        let lastDoc = snapshot.documents.last
        return (processes, lastDoc)
    }

    func createProfileRequest(profileRequest: ProfileRequest) async throws -> String {
        let ref = db.collection("profileRequests").document()
        try await ref.setData(from: profileRequest)
        return ref.documentID
    }

    func getProfileRequests(lastDocument: DocumentSnapshot? = nil, limit: Int) async throws -> ([ProfileRequest], DocumentSnapshot?) {
        var query = db.collection("profileRequests")
            .order(by: "datum", descending: true)
            .limit(to: limit)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        let snapshot = try await query.getDocuments()
        let requests = snapshot.documents.compactMap { doc -> ProfileRequest? in
            do {
                var request = try doc.data(as: ProfileRequest.self)
                request.id = doc.documentID
                return request
            } catch {
                print("Fehler beim Dekodieren der Profil-Anfrage \(doc.documentID): \(error)")
                return nil
            }
        }
        let lastDoc = snapshot.documents.last
        return (requests, lastDoc)
    }

    func uploadFile(documentID: String, data: Data, collection: String, fileName: String) async throws -> String {
        let storageRef = Storage.storage().reference().child("\(collection)/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }

    func migrateTransferProcesses() async throws {
        let snapshot = try await db.collection("transferProcesses").getDocuments()
        for doc in snapshot.documents {
            var process = try doc.data(as: TransferProcess.self)
            
            let clientSnapshot = try await db.collection("clients").document(process.clientID).getDocument()
            let client = try clientSnapshot.data(as: Client.self)
            let clubSnapshot = try await db.collection("clubs").document(process.vereinID).getDocument()
            let club = try clubSnapshot.data(as: Club.self)
            
            let updatedData: [String: Any] = [
                "title": "\(client.vorname ?? "Unbekannt") -> \(club.name ?? "Unbekannt")",
                "sponsorID": NSNull()
            ]
            try await doc.reference.updateData(updatedData)
        }
    }
    
    struct MatchingWeights: Codable {
        var position: Double
        var liga: Double
        var gehalt: Double
        var abteilung: Double
        var nationalitaet: Double
        var spielstil: Double
        var groesse: Double
        var tempo: Double
        var zweikampfstärke: Double
        var einsGegenEins: Double
    }

    func getMatchingWeights() async throws -> MatchingWeights {
        let doc = try await db.collection("settings").document("matching_weights").getDocument()
        if let data = doc.data() {
            return MatchingWeights(
                position: data["position"] as? Double ?? 20.0,
                liga: data["liga"] as? Double ?? 15.0,
                gehalt: data["gehalt"] as? Double ?? 10.0,
                abteilung: data["abteilung"] as? Double ?? 10.0,
                nationalitaet: data["nationalitaet"] as? Double ?? 5.0,
                spielstil: data["spielstil"] as? Double ?? 15.0,
                groesse: data["groesse"] as? Double ?? 5.0,
                tempo: data["tempo"] as? Double ?? 10.0,
                zweikampfstärke: data["zweikampfstärke"] as? Double ?? 10.0,
                einsGegenEins: data["einsGegenEins"] as? Double ?? 10.0
            )
        }
        return MatchingWeights(
            position: 20.0, liga: 15.0, gehalt: 10.0, abteilung: 10.0, nationalitaet: 5.0,
            spielstil: 15.0, groesse: 5.0, tempo: 10.0, zweikampfstärke: 10.0, einsGegenEins: 10.0
        )
    }

    func calculateMatchScore(client: Client, club: Club, weights: MatchingWeights) -> Double {
        var score: Double = 0.0

        if let clientPosition = client.positionFeld?.first,
           club.mensDepartment?.clients?.contains(where: { $0 == clientPosition }) == true {
            score += weights.position
        }

        if let clientLiga = client.liga, let clubLiga = club.mensDepartment?.league, clientLiga == clubLiga {
            score += weights.liga
        }

        if let clientGehalt = client.gehalt, clientGehalt <= 100000 {
            score += weights.gehalt
        }

        if let clientAbteilung = client.abteilung, clientAbteilung == club.abteilungForGender(client.geschlecht) {
            score += weights.abteilung
        }

        if let clientNationalitaet = client.nationalitaet, let clubLand = club.sharedInfo?.land,
           clientNationalitaet.contains(clubLand) {
            score += weights.nationalitaet
        }

        if let clientSpielstil = client.spielstil, clientSpielstil == "offensiv" {
            score += weights.spielstil
        }

        if client.groesse != nil {
            score += weights.groesse * 0.5
        }

        if let clientTempo = client.tempo, clientTempo >= 70 {
            score += weights.tempo
        }

        if let clientZweikampfstärke = client.zweikampfstärke, clientZweikampfstärke >= 80 {
            score += weights.zweikampfstärke
        }

        if let clientEinsGegenEins = client.einsGegenEins, clientEinsGegenEins >= 70 {
            score += weights.einsGegenEins
        }

        return min(score, 100.0)
    }

    func generateMatches() async throws -> [Matching] {
        let weights = try await getMatchingWeights()
        let (clients, _) = try await getClients(lastDocument: nil, limit: 1000)
        let (clubs, _) = try await getClubs(lastDocument: nil, limit: 1000)
        var matches: [Matching] = []

        for client in clients {
            for club in clubs {
                let score = calculateMatchScore(client: client, club: club, weights: weights)
                if score > 50.0 {
                    let match = Matching(
                        clientID: client.id ?? "",
                        vereinID: club.id ?? "",
                        matchScore: score,
                        status: "pending",
                        createdAt: Date()
                    )
                    matches.append(match)
                    try await db.collection("matches").document(match.id).setData(from: match)
                    try await sendMatchNotification(match: match)
                }
            }
        }

        return matches.sorted { $0.matchScore > $1.matchScore }
    }

    func sendMatchNotification(match: Matching) async throws {
        let notification = Notification(
            id: UUID().uuidString,
            userID: "all_mitarbeiter",
            title: "Neues Match gefunden",
            message: "Ein neues Match zwischen Klient \(match.clientID) und Verein \(match.vereinID) wurde gefunden (Score: \(match.matchScore))",
            timestamp: Date(),
            isRead: false
        )
        try await db.collection("notifications").document(notification.id).setData(from: notification)
    }

    func saveMatchFeedback(feedback: MatchFeedback) async throws {
        try await db.collection("match_feedback").document(feedback.id).setData(from: feedback)
        
        try await db.collection("matches").document(feedback.matchID).updateData([
            "status": feedback.status
        ])
        
        if feedback.status == "rejected", let reason = feedback.reason {
            let weightsRef = db.collection("settings").document("matching_weights")
            if reason.contains("Position") {
                try await weightsRef.updateData(["position": FieldValue.increment(-1.0)])
            }
        }
    }

    func awardPoints(to userID: String, points: Int) async throws {
        let userRef = db.collection("users").document(userID)
        try await userRef.updateData([
            "points": FieldValue.increment(Int64(points))
        ])
    }

    func awardBadge(to userID: String, badge: String) async throws {
        let userRef = db.collection("users").document(userID)
        try await userRef.updateData([
            "badges": FieldValue.arrayUnion([badge])
        ])
    }

    func updateChallengeProgress(userID: String, challengeType: String, increment: Int) async throws {
        let userRef = db.collection("users").document(userID)
        let snapshot = try await userRef.getDocument()
        guard let user = try? snapshot.data(as: User.self) else { return }
        
        var challenges = user.challenges ?? []
        if let index = challenges.firstIndex(where: { $0.type == challengeType && !$0.completed }) {
            challenges[index].progress += increment
            if challenges[index].progress >= challenges[index].goal {
                challenges[index].completed = true
                try await awardPoints(to: userID, points: challenges[index].points)
                let notification = Notification(
                    id: UUID().uuidString,
                    userID: userID,
                    title: "Herausforderung abgeschlossen",
                    message: "Du hast die Herausforderung '\(challenges[index].title)' abgeschlossen und \(challenges[index].points) Punkte erhalten!",
                    timestamp: Date(),
                    isRead: false
                )
                try await db.collection("notifications").document(notification.id).setData(from: notification)
            }
        }
        try await userRef.updateData(["challenges": challenges.map { try! Firestore.Encoder().encode($0) }])
    }

    func generateEmail(for process: TransferProcess, step: Step, language: String = "Deutsch") async throws -> String {
        let emailContent = """
        Betreff: \(step.typ) für \(process.clientID) - \(process.vereinID)
        Sehr geehrte Damen und Herren,
        im Rahmen des Transferprozesses für \(process.clientID) möchten wir Ihnen folgende Informationen zukommen lassen:
        - Schritt: \(step.typ)
        - Status: \(step.status)
        - Datum: \(DateFormatter.localizedString(from: step.datum, dateStyle: .medium, timeStyle: .none))
        Mit freundlichen Grüßen,
        Sports Transfer Team
        """
        if let userID = process.mitarbeiterID {
            try await awardPoints(to: userID, points: 10)
            try await updateChallengeProgress(userID: userID, challengeType: "send_emails", increment: 1)
            let snapshot = try await db.collection("users").document(userID).getDocument()
            if let user = try? snapshot.data(as: User.self), !(user.badges?.contains("first_email") ?? false) {
                try await awardBadge(to: userID, badge: "first_email")
            }
        }
        return emailContent
    }
    
    func initializeUserChallenges(userID: String) async throws {
        let challenges = [
            Challenge(
                title: "Versende 3 E-Mails an Vereine",
                description: "Versende 3 E-Mails, um 50 Punkte zu erhalten.",
                points: 50,
                progress: 0,
                goal: 3,
                type: "send_emails",
                completed: false
            ),
            Challenge(
                title: "Aquiriere 1 Klienten der Kategorie 2",
                description: "Aquiriere einen Klienten der Kategorie 2, um 100 Punkte zu erhalten.",
                points: 100,
                progress: 0,
                goal: 1,
                type: "acquire_client",
                completed: false
            )
        ]
        try await db.collection("users").document(userID).updateData([
            "challenges": challenges.map { try! Firestore.Encoder().encode($0) }
        ])
    }

    func updateTransferProcess(transferProcess: TransferProcess) async throws {
        guard let id = transferProcess.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine ID vorhanden"])
        }
        for step in transferProcess.schritte {
            try validateStep(step: step, forProcess: transferProcess)
        }
        try await db.collection("transferProcesses").document(id).setData(from: transferProcess, merge: true)
        try await updateProcessStatus(process: transferProcess, collection: "transferProcesses")
    }

    func deleteTransferProcess(id: String) async throws {
        try await db.collection("transferProcesses").document(id).delete()
    }

    func updateSponsoringProcess(sponsoringProcess: SponsoringProcess) async throws {
        guard let id = sponsoringProcess.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine ID vorhanden"])
        }
        for step in sponsoringProcess.schritte {
            try validateStep(step: step, forProcess: sponsoringProcess)
        }
        try await db.collection("sponsoringProcesses").document(id).setData(from: sponsoringProcess, merge: true)
        try await updateProcessStatus(process: sponsoringProcess, collection: "sponsoringProcesses")
    }

    func deleteSponsoringProcess(id: String) async throws {
        try await db.collection("sponsoringProcesses").document(id).delete()
    }

    func updateProfileRequest(profileRequest: ProfileRequest) async throws {
        guard let id = profileRequest.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine ID vorhanden"])
        }
        guard !profileRequest.vereinID.isEmpty else {
            throw ValidationError.missingField("Verein-ID")
        }
        guard !profileRequest.gesuchtePositionen.isEmpty else {
            throw ValidationError.missingField("Gesuchte Positionen")
        }
        try await db.collection("profileRequests").document(id).setData(from: profileRequest, merge: true)
    }

    func deleteProfileRequest(id: String) async throws {
        try await db.collection("profileRequests").document(id).delete()
    }

    // Funktion zur Statusaktualisierung
    func updateProcessStatus<T: Codable & Identifiable>(process: T, collection: String) async throws {
        guard let id = (process as? AnyIdentifiable)?.id else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine ID vorhanden"])
        }
        
        var steps: [Step] = []
        var updatedProcess = process
        
        if let transfer = process as? TransferProcess {
            steps = transfer.schritte
            var updatedTransfer = transfer
            updatedTransfer.status = calculateStatus(from: steps)
            updatedProcess = updatedTransfer as! T
        } else if let sponsoring = process as? SponsoringProcess {
            steps = sponsoring.schritte
            var updatedSponsoring = sponsoring
            updatedSponsoring.status = calculateStatus(from: steps)
            updatedProcess = updatedSponsoring as! T
        } else if process is ProfileRequest {
            return // Profil-Anfragen haben keine Schritte, Status bleibt manuell
        }
        
        try await db.collection(collection).document(id).setData(from: updatedProcess, merge: true)
    }
    
    // Hilfsfunktion zur Statusberechnung
    private func calculateStatus(from steps: [Step]) -> String {
        if steps.isEmpty {
            return "in Bearbeitung"
        }
        let allCompleted = steps.allSatisfy { $0.status == "abgeschlossen" }
        let hasNo = steps.contains { $0.entscheidung == "Nein" }
        
        if hasNo {
            return "abgebrochen"
        } else if allCompleted {
            return "abgeschlossen"
        } else {
            return "in Bearbeitung"
        }
    }
    
    // Validierung vor dem Speichern eines Schrittes
    func validateStep(step: Step, forProcess process: Any) throws {
        switch step.typ {
        case "initialeKontaktaufnahme":
            guard step.funktionär != nil else {
                throw ValidationError.missingField("Funktionär-ID")
            }
        case "informationsaustausch":
            guard step.checkliste?.contains("CV bereit") == true else {
                throw ValidationError.missingField("Spieler-CV in Checkliste")
            }
        case "vertragVerhandeln":
            if let transfer = process as? TransferProcess {
                guard transfer.konditionen != nil else {
                    throw ValidationError.missingField("Konditionen")
                }
            } else if let sponsoring = process as? SponsoringProcess {
                guard sponsoring.konditionen != nil else {
                    throw ValidationError.missingField("Konditionen")
                }
            }
        default:
            break
        }
    }

    // Fehler-Typ für Validierung
    enum ValidationError: Error {
        case missingField(String)
        
        var localizedDescription: String {
            switch self {
            case .missingField(let field):
                return "Pflichtfeld fehlt: \(field)"
            }
        }
    }
}
