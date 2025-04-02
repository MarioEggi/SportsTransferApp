import SwiftUI
import FirebaseFirestore

enum SortOption: String, CaseIterable {
    case name = "Name"
    case verein = "Verein"
    case position = "Position"
    case alter = "Alter"
}

class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var filteredClients: [Client] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = []
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    @Published var filterClub: String? = nil
    @Published var filterGender: String? = nil
    @Published var filterType: String? = nil
    @Published var sortOption: SortOption = .name
    @Published var searchText: String = ""

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func loadClients() async {
        await MainActor.run { isLoading = true }
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
            await MainActor.run {
                clients = loadedClients
                applyFiltersAndSorting()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Klienten: \(error.localizedDescription)")
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
                await MainActor.run {
                    clients.append(updatedClient)
                    applyFiltersAndSorting()
                }
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
            await MainActor.run {
                clients.removeAll { $0.id == id }
                applyFiltersAndSorting()
            }
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
        }
    }

    func applyFiltersAndSorting() {
        var filtered = clients

        // Filter nach Verein
        if let filterClub = filterClub {
            filtered = filtered.filter { client in
                client.vereinID == filterClub
            }
        }

        // Filter nach Geschlecht
        if let filterGender = filterGender {
            filtered = filtered.filter { $0.geschlecht == filterGender }
        }

        // Filter nach Typ
        if let filterType = filterType {
            filtered = filtered.filter { $0.typ == filterType }
        }

        // Suche nach Text
        if !searchText.isEmpty {
            filtered = filtered.filter { client in
                let fullName = "\(client.vorname) \(client.name)".lowercased()
                return fullName.contains(searchText.lowercased())
            }
        }

        // Sortierung
        switch sortOption {
        case .name:
            filtered.sort { $0.name < $1.name }
        case .verein:
            filtered.sort { ($0.vereinID ?? "") < ($1.vereinID ?? "") }
        case .position:
            filtered.sort { ($0.positionFeld?.first ?? "") < ($1.positionFeld?.first ?? "") }
        case .alter:
            filtered.sort { client1, client2 in
                let age1 = client1.geburtsdatum.map { Calendar.current.dateComponents([.year], from: $0, to: Date()).year ?? 0 } ?? 0
                let age2 = client2.geburtsdatum.map { Calendar.current.dateComponents([.year], from: $0, to: Date()).year ?? 0 } ?? 0
                return age1 < age2
            }
        }

        filteredClients = filtered
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
