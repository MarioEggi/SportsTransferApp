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
    private var lastDocument: QueryDocumentSnapshot? // Für Pagination
    private let pageSize = 20 // Seitengröße für Pagination

    init() {
        setupRealtimeListener()
    }

    deinit {
        listener?.remove()
    }

    private func setupRealtimeListener() {
        listener = Firestore.firestore().collection("clients")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
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
                        let client = try doc.data(as: Client.self)
                        print("Geladener Klient: \(client)")
                        return client
                    } catch {
                        print("Fehler beim Dekodieren des Klienten \(doc.documentID): \(error)")
                        print("Rohdaten des Dokuments: \(doc.data())")
                        return nil
                    }
                }
                DispatchQueue.main.async {
                    let uniqueClients = Dictionary(uniqueKeysWithValues: updatedClients.map { ($0.id ?? UUID().uuidString, $0) }).values
                    print("Aktualisierte Klienten: \(updatedClients)")
                    self.clients = Array(uniqueClients)
                    self.applyFiltersAndSorting()
                    self.isLoading = false
                }
            }
    }

    func loadClients(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newClients, newLastDoc) = try await FirestoreManager.shared.getClients(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { clients.append(contentsOf: newClients) } else { clients = newClients }
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

    func loadClients(userID: String) async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            await MainActor.run {
                self.clients = loadedClients.filter { $0.userID == userID }
                self.applyFiltersAndSorting()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
                self.isLoading = false
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
                try await FirestoreManager.shared.createClient(client: client)
                print("ClientViewModel - Neuer Client erstellt in Firestore")
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
                print("ClientViewModel - Fehler beim Speichern: \(error.localizedDescription)")
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
