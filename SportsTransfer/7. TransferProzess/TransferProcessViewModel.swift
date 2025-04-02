import SwiftUI
import FirebaseFirestore

class TransferProcessViewModel: ObservableObject {
    @Published var transferProcesses: [TransferProcess] = []
    @Published var clients: [Client] = []
    @Published var clubs: [Club] = []
    @Published var mitarbeiter: [String] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var showingNewProcess: Bool = false // Für EmployeeView
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    private let authManager: AuthManager // Hinzugefügt
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func loadTransferProcesses(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (processes, lastDoc) = try await FirestoreManager.shared.getTransferProcesses(
                lastDocument: loadMore ? lastDocument : nil, limit: pageSize
            )
            let (clients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            
            let mitarbeiterSet = Set(processes.compactMap { $0.mitarbeiterID })
            
            await MainActor.run {
                if loadMore {
                    transferProcesses.append(contentsOf: processes)
                } else {
                    transferProcesses = processes
                }
                self.clients = clients
                self.clubs = clubs
                self.mitarbeiter = Array(mitarbeiterSet)
                lastDocument = lastDoc
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func updateTransferProcess(_ process: TransferProcess) async {
        do {
            try await FirestoreManager.shared.updateTransferProcess(transferProcess: process)
            await loadTransferProcesses()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Aktualisieren: \(error.localizedDescription)"
            }
        }
    }
    
    // Neue Methode für E-Mail-Generierung
    func generateEmail(for process: TransferProcess, step: Step, language: String) async -> String {
        do {
            return try await FirestoreManager.shared.generateEmail(for: process, step: step, language: language)
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Generieren der E-Mail: \(error.localizedDescription)"
            }
            return ""
        }
    }
}
