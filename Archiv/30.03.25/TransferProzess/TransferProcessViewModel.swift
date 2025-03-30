import SwiftUI
import FirebaseFirestore

class TransferProcessViewModel: ObservableObject {
    @Published var transferProcesses: [TransferProcess] = []
    @Published var clients: [Client] = []
    @Published var clubs: [Club] = []
    @Published var funktionäre: [Funktionär] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var dueReminders: [Reminder] = []
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
        Task { await loadInitialData() }
    }

    func loadTransferProcesses(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newProcesses, newLastDoc) = try await FirestoreManager.shared.getTransferProcesses(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { transferProcesses.append(contentsOf: newProcesses) } else { transferProcesses = newProcesses }
                lastDocument = newLastDoc
                isLoading = false
                updateDueReminders()
            }
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Laden der Transferprozesse: \(error.localizedDescription)"; isLoading = false }
        }
    }

    func loadInitialData() async {
        await MainActor.run { isLoading = true }
        do {
            let loadedClients: [Client]
            if authManager.userRole == .mitarbeiter {
                let (clients, _) = try await FirestoreManager.shared.getAllClients(lastDocument: nil, limit: 1000)
                loadedClients = clients
            } else if let userID = authManager.userID {
                let (clients, _) = try await FirestoreManager.shared.getClients(forUserID: userID, lastDocument: nil, limit: 1000)
                loadedClients = clients
            } else {
                loadedClients = []
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer-ID nicht verfügbar"])
            }

            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            let (loadedFunktionäre, _) = try await FirestoreManager.shared.getFunktionäre(lastDocument: nil, limit: 1000)
            await MainActor.run {
                clients = loadedClients
                clubs = loadedClubs
                funktionäre = loadedFunktionäre
                isLoading = false
            }
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Laden der Initialdaten: \(error.localizedDescription)"; isLoading = false }
        }
    }

    func generateEmail(for process: TransferProcess, step: Step) -> String {
        guard let client = clients.first(where: { $0.id == process.clientID }),
              let club = clubs.first(where: { $0.id == process.vereinID }) else { return "Daten nicht verfügbar" }

        let subject = "Betreff: \(step.typ) für \(client.vorname) \(client.name)"
        let body = """
        Sehr geehrte Damen und Herren,

        im Rahmen des Transferprozesses für \(client.vorname) \(client.name) möchten wir Sie über den aktuellen Stand informieren:
        - Schritt: \(step.typ)
        - Status: \(step.status)
        - Datum: \(dateFormatter.string(from: step.datum))
        - Notizen: \(step.notizen ?? "Keine")

        Bitte setzen Sie sich bei Rückfragen mit uns in Verbindung.

        Mit freundlichen Grüßen,
        [Ihr Name]
        Sports Transfer Team
        """
        return "\(subject)\n\n\(body)"
    }

    func saveTransferProcess(_ process: TransferProcess) async {
        do {
            if process.id != nil {
                try await FirestoreManager.shared.updateTransferProcess(transferProcess: process)
            } else {
                let newID = try await FirestoreManager.shared.createTransferProcess(transferProcess: process)
                var updatedProcess = process
                updatedProcess.id = newID
                transferProcesses.append(updatedProcess)
            }
            await loadTransferProcesses()
        } catch {
            await MainActor.run { errorMessage = "Fehler beim Speichern: \(error.localizedDescription)" }
        }
    }

    private func updateDueReminders() {
        let today = Date()
        var allDueReminders: [Reminder] = []
        for process in transferProcesses {
            if let reminders = process.erinnerungen {
                let due = reminders.filter { Calendar.current.startOfDay(for: $0.datum) <= Calendar.current.startOfDay(for: today) }
                allDueReminders.append(contentsOf: due)
            }
        }
        dueReminders = allDueReminders.sorted { $0.datum < $1.datum }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
