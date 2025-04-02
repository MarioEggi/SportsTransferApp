import SwiftUI
import FirebaseFirestore

class WorkflowViewModel: ObservableObject {
    @Published var processes: [AnyProcess] = []
    @Published var clubs: [Club] = []
    @Published var clients: [Client] = []
    @Published var sponsors: [Sponsor] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    private var lastTransferDoc: DocumentSnapshot?
    private var lastSponsoringDoc: DocumentSnapshot?
    private var lastProfileDoc: DocumentSnapshot?
    private let pageSize = 20
    
    func loadProcesses(loadMore: Bool = false) async {
        await MainActor.run { isLoading = true }
        do {
            let (transfers, transferDoc) = try await FirestoreManager.shared.getTransferProcesses(lastDocument: loadMore ? lastTransferDoc : nil, limit: pageSize)
            let (sponsorings, sponsoringDoc) = try await FirestoreManager.shared.getSponsoringProcesses(lastDocument: loadMore ? lastSponsoringDoc : nil, limit: pageSize)
            let (profiles, profileDoc) = try await FirestoreManager.shared.getProfileRequests(lastDocument: loadMore ? lastProfileDoc : nil, limit: pageSize)
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
            let (loadedSponsors, _) = try await FirestoreManager.shared.getSponsors(lastDocument: nil, limit: 1000)
            
            let newProcesses = transfers.map { AnyProcess(transfer: $0, clients: loadedClients, clubs: loadedClubs) } +
                              sponsorings.map { AnyProcess(sponsoring: $0, clients: loadedClients, sponsors: loadedSponsors) } +
                              profiles.map { AnyProcess(profile: $0, clubs: loadedClubs) }
            
            await MainActor.run {
                if loadMore {
                    processes.append(contentsOf: newProcesses)
                } else {
                    processes = newProcesses
                    clubs = loadedClubs
                    clients = loadedClients
                    sponsors = loadedSponsors
                }
                lastTransferDoc = transferDoc
                lastSponsoringDoc = sponsoringDoc
                lastProfileDoc = profileDoc
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
