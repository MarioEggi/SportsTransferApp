import SwiftUI
import FirebaseFirestore

class TransferViewModel: ObservableObject {
    @Published var transfers: [Transfer] = []
    @Published var clients: [Client] = []
    @Published var clubs: [Club] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = [] // Warteschlange für Fehlermeldungen
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    func loadTransfers(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newTransfers, newLastDoc) = try await FirestoreManager.shared.getTransfers(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { transfers.append(contentsOf: newTransfers) } else { transfers = newTransfers }
                lastDocument = newLastDoc
                isLoading = false
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler: \(error.localizedDescription)")
                isLoading = false
            }
        }

        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                clients = loadedClients
                clubs = loadedClubs
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Laden der Klienten/Vereine: \(error.localizedDescription)")
            }
        }
    }

    func saveTransfer(_ transfer: Transfer) async {
        do {
            if transfer.id != nil {
                try await FirestoreManager.shared.updateTransfer(transfer: transfer)
            } else {
                try await FirestoreManager.shared.createTransfer(transfer: transfer)
            }
            await loadTransfers()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    func deleteTransfer(_ transfer: Transfer) async {
        guard let id = transfer.id else {
            await MainActor.run {
                addErrorToQueue("Keine Transfer-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteTransfer(transferID: id)
            await loadTransfers()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }

    func recentTransfers(days: Int) -> [Transfer] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return transfers
            .filter { $0.datum >= cutoffDate }
            .sorted { $0.datum > $1.datum }
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
