import SwiftUI
import FirebaseFirestore

struct ContractDetailView: View {
    let contract: Contract
    @State private var showingEditSheet = false
    @State private var client: Client? = nil
    @State private var club: Club? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Vertragsdetails")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                VStack(alignment: .leading, spacing: 10) {
                    if let client = client {
                        Text("Klient: \(client.vorname) \(client.name)")
                            .font(.headline)
                    }
                    if let club = club {
                        Text("Verein: \(club.name)")
                            .font(.headline)
                    }
                    Text("Startdatum: \(dateFormatter.string(from: contract.startDatum))")
                    if let endDatum = contract.endDatum {
                        Text("Enddatum: \(dateFormatter.string(from: endDatum))")
                    }
                    if let gehalt = contract.gehalt {
                        Text("Gehalt: \(String(format: "%.2f €", gehalt))")
                    }
                    if let vertragsdetails = contract.vertragsdetails {
                        Text("Details: \(vertragsdetails)")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Button("Bearbeiten") {
                    showingEditSheet = true
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Spacer()
            }
            .navigationTitle("Vertrag")
            .task {
                await loadClientAndClub()
            }
            .sheet(isPresented: $showingEditSheet) {
                AddContractView(
                    contract: .constant(contract),
                    isEditing: true,
                    onSave: { updatedContract in
                        // Hier könnte man die Änderungen speichern, aber das übernimmt die AddContractView
                        showingEditSheet = false
                    },
                    onCancel: {
                        showingEditSheet = false
                    }
                )
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private func loadClientAndClub() async {
        do {
            if let clientID = contract.clientID {
                let clients = try await FirestoreManager.shared.getClients()
                await MainActor.run {
                    self.client = clients.first { $0.id == clientID }
                }
            }
            if let vereinID = contract.vereinID {
                let clubs = try await FirestoreManager.shared.getClubs()
                await MainActor.run {
                    self.club = clubs.first { $0.name == vereinID }
                }
            }
        } catch {
            print("Fehler beim Laden der Daten: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContractDetailView(contract: Contract(
        id: "1",
        clientID: "client1",
        vereinID: "Verein1",
        startDatum: Date(),
        endDatum: Date().addingTimeInterval(3600 * 24 * 365),
        gehalt: 50000.0,
        vertragsdetails: "Standardvertrag"
    ))
    .environmentObject(AuthManager())
}
