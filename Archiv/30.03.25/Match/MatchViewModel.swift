import SwiftUI
import FirebaseFirestore

class MatchViewModel: ObservableObject {
    @Published var matches: [Match] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = [] // Warteschlange für Fehlermeldungen
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    func loadMatches(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newMatches, newLastDoc) = try await FirestoreManager.shared.getMatches(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { matches.append(contentsOf: newMatches) } else { matches = newMatches }
                lastDocument = newLastDoc
                isLoading = false
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    func saveMatch(_ match: Match) async {
        do {
            if match.id != nil {
                try await FirestoreManager.shared.updateMatch(match: match)
            } else {
                try await FirestoreManager.shared.createMatch(match: match)
            }
            await loadMatches()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    func deleteMatch(_ match: Match) async {
        guard let id = match.id else {
            await MainActor.run {
                addErrorToQueue("Keine Match-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteMatch(matchID: id)
            await loadMatches()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
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
