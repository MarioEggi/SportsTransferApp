import SwiftUI
import FirebaseFirestore

struct ContractDetailView: View {
    let contract: Contract
    @EnvironmentObject var authManager: AuthManager
    @State private var showingEditSheet = false
    @State private var client: Client? = nil
    @State private var club: Club? = nil
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Vertragsdetails")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                    .foregroundColor(.white) // Weiße Schrift

                VStack(alignment: .leading, spacing: 10) {
                    if let client = client {
                        Text("Klient: \(client.vorname) \(client.name)")
                            .font(.headline)
                            .foregroundColor(.white) // Weiße Schrift
                    }
                    if let club = club {
                        Text("Verein: \(club.name)")
                            .font(.headline)
                            .foregroundColor(.white) // Weiße Schrift
                    }
                    Text("Startdatum: \(dateFormatter.string(from: contract.startDatum))")
                        .foregroundColor(.white) // Weiße Schrift
                    if let endDatum = contract.endDatum {
                        Text("Enddatum: \(dateFormatter.string(from: endDatum))")
                            .foregroundColor(.white) // Weiße Schrift
                    }
                    if let gehalt = contract.gehalt {
                        Text("Gehalt: \(String(format: "%.2f €", gehalt))")
                            .foregroundColor(.white) // Weiße Schrift
                    }
                    if let vertragsdetails = contract.vertragsdetails {
                        Text("Details: \(vertragsdetails)")
                            .foregroundColor(.white) // Weiße Schrift
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2)) // Dunklerer Hintergrund
                .cornerRadius(10)

                if authManager.userRole == .mitarbeiter {
                    Button("Bearbeiten") {
                        showingEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue) // Blaue Schaltfläche
                    .foregroundColor(.white) // Weiße Schrift
                    .padding()
                }

                Spacer()
            }
            .padding()
            .background(Color.black) // Schwarzer Hintergrund für die gesamte View
            .navigationTitle("Vertrag")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .task {
                await loadClientAndClub()
            }
            .sheet(isPresented: $showingEditSheet) {
                AddContractView(
                    contract: .constant(contract),
                    isEditing: true,
                    onSave: { _ in
                        showingEditSheet = false
                    },
                    onCancel: {
                        showingEditSheet = false
                    }
                )
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(.white),
                    message: Text(errorMessage).foregroundColor(.white),
                    dismissButton: .default(Text("OK").foregroundColor(.white)) {
                        errorMessage = ""
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
                let (clients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
                await MainActor.run {
                    self.client = clients.first { $0.id == clientID }
                }
            }
            if let vereinID = contract.vereinID {
                let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
                await MainActor.run {
                    self.club = clubs.first { $0.name == vereinID }
                }
            }
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
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
