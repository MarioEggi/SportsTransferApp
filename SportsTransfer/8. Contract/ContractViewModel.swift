import SwiftUI
import FirebaseFirestore

class ContractViewModel: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var clients: [Client] = []
    @Published var clubs: [Club] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = [] // Warteschlange für Fehlermeldungen
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    func loadContracts(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newContracts, newLastDoc) = try await FirestoreManager.shared.getContracts(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { contracts.append(contentsOf: newContracts) } else { contracts = newContracts }
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

    func saveContract(_ contract: Contract) async {
        do {
            if contract.id != nil {
                try await FirestoreManager.shared.updateContract(contract: contract)
            } else {
                try await FirestoreManager.shared.createContract(contract: contract)
            }
            await loadContracts()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    func deleteContract(_ contract: Contract) async {
        guard let id = contract.id else {
            await MainActor.run {
                addErrorToQueue("Keine Vertrags-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteContract(contractID: id)
            await loadContracts()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }

    func expiringContracts(days: Int) -> [Contract] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: Date())!
        return contracts
            .filter { contract in
                guard let endDatum = contract.endDatum else { return false }
                return endDatum <= cutoffDate && endDatum >= Date()
            }
            .sorted { $0.endDatum! < $1.endDatum! }
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
