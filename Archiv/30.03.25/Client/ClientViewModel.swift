import SwiftUI
import FirebaseFirestore

class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var filteredClients: [Client] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = []
    @Published var isShowingError = false
    @Published var isLoading: Bool = false

    // Filter und Sortierung
    @Published var filterClub: String? = nil
    @Published var filterGender: String? = nil
    @Published var filterType: String? = nil
    @Published var sortOption: Constants.SortOption = .nameAscending

    private var listener: ListenerRegistration?
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20
    private let authManager: AuthManager // Neu: AuthManager injizieren

    init(authManager: AuthManager) {
        self.authManager = authManager
        setupRealtimeListener()
    }

    deinit {
        listener?.remove()
    }

    private func setupRealtimeListener() {
        var query: Query = Firestore.firestore().collection("clients").order(by: "name")

        // Filterung basierend auf der Rolle des Benutzers
        if authManager.userRole == .klient, let userID = authManager.userID {
            query = query.whereField("userID", isEqualTo: userID)
        }

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                self.addErrorToQueue("Fehler beim Listener: \(error.localizedDescription)")
                print("Listener-Fehler: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("Keine Dokumente gefunden")
                return
            }
            print("Anzahl der Dokumente: \(documents.count)")
            let updatedClients = documents.compactMap { doc -> Client? in
                do {
                    var client = try doc.data(as: Client.self)
                    client.id = doc.documentID // Explizite ID-Zuweisung
                    print("Geladener Klient - ID: \(client.id ?? "nil"), Name: \(client.vorname) \(client.name)")
                    return client
                } catch {
                    print("Fehler beim Dekodieren des Klienten \(doc.documentID): \(error)")
                    print("Rohdaten des Dokuments: \(doc.data())")
                    return nil
                }
            }
            DispatchQueue.main.async {
                let uniqueClients = Dictionary(uniqueKeysWithValues: updatedClients.map { ($0.id ?? UUID().uuidString, $0) }).values
                print("Aktualisierte Klienten: \(updatedClients.map { "\($0.id ?? "nil"): \($0.vorname) \($0.name)" })")
                self.clients = Array(uniqueClients)
                self.applyFiltersAndSorting()
                self.isLoading = false
            }
        }
    }

    func loadClients(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newClients, newLastDoc): ([Client], QueryDocumentSnapshot?)
            if authManager.userRole == .mitarbeiter {
                (newClients, newLastDoc) = try await FirestoreManager.shared.getAllClients(
                    lastDocument: loadMore ? lastDocument : nil,
                    limit: pageSize
                )
            } else if let userID = authManager.userID {
                (newClients, newLastDoc) = try await FirestoreManager.shared.getClients(
                    forUserID: userID,
                    lastDocument: loadMore ? lastDocument : nil,
                    limit: pageSize
                )
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer-ID nicht verfügbar"])
            }
            await MainActor.run {
                if loadMore {
                    clients.append(contentsOf: newClients)
                } else {
                    clients = newClients
                }
                lastDocument = newLastDoc
                isLoading = false
                applyFiltersAndSorting()
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    func loadClients(userID: String, loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (loadedClients, newLastDoc) = try await FirestoreManager.shared.getClients(
                forUserID: userID,
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore {
                    clients.append(contentsOf: loadedClients)
                } else {
                    clients = loadedClients
                }
                lastDocument = newLastDoc
                isLoading = false
                applyFiltersAndSorting()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func saveClient(_ client: Client) async {
        do {
            print("ClientViewModel - Client zum Speichern: \(client)")
            if client.id != nil {
                try await FirestoreManager.shared.updateClient(client: client)
                print("ClientViewModel - Client erfolgreich aktualisiert in Firestore")
            } else {
                let newClientID = try await FirestoreManager.shared.createClient(client: client)
                var updatedClient = client
                updatedClient.id = newClientID
                print("ClientViewModel - Neuer Client erstellt in Firestore mit ID: \(newClientID)")
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
                print("ClientViewModel - Fehler beim Speichern: \(error)")
            }
        }
    }

    func deleteClient(_ client: Client) async {
        guard let id = client.id else {
            await MainActor.run {
                addErrorToQueue("Keine Klienten-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteClient(clientID: id)
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }

    func updateClientLocally(_ updatedClient: Client) {
        if let index = clients.firstIndex(where: { $0.id == updatedClient.id }) {
            DispatchQueue.main.async {
                self.clients[index] = updatedClient
                self.applyFiltersAndSorting()
                print("ClientViewModel - Client lokal aktualisiert: \(updatedClient)")
            }
            Task {
                do {
                    try await FirestoreManager.shared.updateClient(client: updatedClient)
                    print("ClientViewModel - Client erfolgreich aktualisiert in Firestore")
                } catch {
                    self.addErrorToQueue("Fehler beim Aktualisieren in Firestore: \(error.localizedDescription)")
                }
            }
        }
    }

    func activeClientsByClub() -> [String: Int] {
        var clientsByClub: [String: Int] = [:]
        for client in clients {
            if let vereinID = client.vereinID {
                clientsByClub[vereinID, default: 0] += 1
            }
        }
        return clientsByClub
    }

    func applyFiltersAndSorting() {
        var result = clients

        if let club = filterClub {
            result = result.filter { $0.vereinID == club }
        }
        if let gender = filterGender {
            result = result.filter { $0.geschlecht == gender }
        }
        if let type = filterType {
            result = result.filter { $0.typ == type }
        }

        switch sortOption {
        case .nameAscending:
            result.sort { ($0.vorname + $0.name) < ($1.vorname + $1.name) }
        case .nameDescending:
            result.sort { ($0.vorname + $0.name) > ($1.vorname + $1.name) }
        case .birthDateAscending:
            result.sort {
                guard let date1 = $0.geburtsdatum, let date2 = $1.geburtsdatum else { return false }
                return date1 < date2
            }
        case .birthDateDescending:
            result.sort {
                guard let date1 = $0.geburtsdatum, let date2 = $1.geburtsdatum else { return false }
                return date1 > date2
            }
        default:
            result.sort { ($0.vorname + $0.name) < ($1.vorname + $1.name) }
        }

        filteredClients = result
    }

    private func addErrorToQueue(_ message: String) {
        errorQueue.append(message)
        if !isShowingError {
            errorMessage = errorQueue.removeFirst()
            isShowingError = true
        }
    }

    func resetError() {
        if !errorQueue.isEmpty {
            errorMessage = errorQueue.removeFirst()
            isShowingError = true
        } else {
            isShowingError = false
            errorMessage = ""
        }
    }
}
