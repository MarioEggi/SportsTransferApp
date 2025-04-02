//
//  ActivityViewModel.swift

import Foundation
import FirebaseFirestore

class ActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    private var lastDocument: QueryDocumentSnapshot?
    private let pageSize = 20

    func loadActivities(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (newActivities, newLastDoc) = try await FirestoreManager.shared.getActivities(lastDocument: loadMore ? lastDocument : nil, limit: pageSize)
            await MainActor.run {
                if loadMore { activities.append(contentsOf: newActivities) } else { activities = newActivities }
                lastDocument = newLastDoc
                isLoading = false
            }
        } catch {
            await MainActor.run { errorMessage = "Fehler: \(error.localizedDescription)"; isLoading = false }
        }
    }

    func recentActivities(days: Int) -> [Activity] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return activities
            .filter { $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
    }
}
