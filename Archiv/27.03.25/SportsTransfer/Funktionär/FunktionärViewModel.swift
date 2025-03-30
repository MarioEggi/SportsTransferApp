import SwiftUI
import FirebaseFirestore

class FunktionärViewModel: ObservableObject {
    @Published var funktionäre: [Funktionär] = []
    @Published var errorMessage: String = ""
    @Published var errorQueue: [String] = []
    @Published var isShowingError = false
    @Published var isLoading: Bool = false
    private var listener: ListenerRegistration?
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    init() {
        setupRealtimeListener()
    }

    deinit {
        listener?.remove()
    }

    private func setupRealtimeListener() {
        listener = Firestore.firestore().collection("funktionare")
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
                let updatedFunktionäre = documents.compactMap { doc -> Funktionär? in
                    do {
                        let funktionär = try doc.data(as: Funktionär.self)
                        print("Geladener Funktionär: \(funktionär)")
                        return funktionär
                    } catch {
                        print("Fehler beim Dekodieren des Funktionärs \(doc.documentID): \(error)")
                        print("Rohdaten des Dokuments: \(doc.data())")
                        return nil
                    }
                }
                DispatchQueue.main.async {
                    self.funktionäre = updatedFunktionäre
                    self.isLoading = false
                }
            }
    }

    func loadFunktionäre(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newFunktionäre, newLastDoc) = try await FirestoreManager.shared.getFunktionäre(
                lastDocument: loadMore ? lastDocument : nil,
                limit: pageSize
            )
            await MainActor.run {
                if loadMore { funktionäre.append(contentsOf: newFunktionäre) } else { funktionäre = newFunktionäre }
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

    func saveFunktionär(_ funktionär: Funktionär) async {
        do {
            if funktionär.id != nil {
                try await FirestoreManager.shared.updateFunktionär(funktionär: funktionär)
                print("Funktionär erfolgreich aktualisiert in Firestore")
            } else {
                try await FirestoreManager.shared.createFunktionär(funktionär: funktionär)
                print("Neuer Funktionär erstellt in Firestore")
            }
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Speichern: \(error.localizedDescription)")
                print("Fehler beim Speichern: \(error.localizedDescription)")
            }
        }
    }

    func deleteFunktionär(_ funktionär: Funktionär) async {
        guard let id = funktionär.id else {
            await MainActor.run {
                addErrorToQueue("Keine Funktionär-ID vorhanden")
            }
            return
        }
        do {
            try await FirestoreManager.shared.deleteFunktionär(funktionärID: id)
        } catch {
            await MainActor.run {
                addErrorToQueue("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }

    func addErrorToQueue(_ message: String) { // Von private zu public/internal geändert
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
