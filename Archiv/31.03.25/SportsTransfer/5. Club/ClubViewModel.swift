import SwiftUI
import FirebaseFirestore

class ClubViewModel: ObservableObject {
    @Published var clubs: [Club] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = []
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    func loadClubs(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newClubs, newLastDoc) = try await FirestoreManager.shared.getClubs(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { clubs.append(contentsOf: newClubs) } else { clubs = newClubs }
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

    func saveClub(_ club: Club) async {
        do {
            if club.id != nil {
                try await FirestoreManager.shared.updateClub(club: club)
            } else {
                try await FirestoreManager.shared.createClub(club: club)
            }
            await loadClubs()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    func deleteClub(_ club: Club) async {
        guard let id = club.id else {
            await MainActor.run {
                addErrorToQueue("Keine Club-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteClub(clubID: id)
            await loadClubs()
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
