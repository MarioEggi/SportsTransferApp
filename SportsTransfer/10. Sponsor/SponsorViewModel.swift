//
//  SponsorViewModel.swift

import SwiftUI
import FirebaseFirestore

class SponsorViewModel: ObservableObject {
    @Published var sponsors: [Sponsor] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = [] // Warteschlange für Fehlermeldungen
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    func loadSponsors(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newSponsors, newLastDoc) = try await FirestoreManager.shared.getSponsors(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { sponsors.append(contentsOf: newSponsors) } else { sponsors = newSponsors }
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

    func saveSponsor(_ sponsor: Sponsor) async {
        do {
            if sponsor.id != nil {
                try await FirestoreManager.shared.updateSponsor(sponsor: sponsor)
            } else {
                try await FirestoreManager.shared.createSponsor(sponsor: sponsor)
            }
            await loadSponsors()
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    func deleteSponsor(_ sponsor: Sponsor) async {
        guard let id = sponsor.id else {
            await MainActor.run {
                addErrorToQueue("Keine Sponsor-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteSponsor(sponsorID: id)
            await loadSponsors()
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
