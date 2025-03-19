import SwiftUI
import FirebaseFirestore

struct ContractListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var contracts: [Contract] = []
    @State private var clients: [Client] = []
    @State private var clubs: [Club] = []
    @State private var showingAddContract = false
    @State private var isEditing = false
    @State private var errorMessage: String = ""
    @State private var newContract = Contract(
        id: nil,
        clientID: nil,
        vereinID: nil,
        startDatum: Date(),
        endDatum: nil,
        gehalt: nil,
        vertragsdetails: nil
    )

    var body: some View {
        NavigationStack {
            List {
                ForEach(contracts) { contract in
                    VStack(alignment: .leading) {
                        if let clientID = contract.clientID,
                           let client = clients.first(where: { $0.id == clientID }) {
                            Text("\(client.vorname) \(client.name)") // Ohne "Klient:"
                                .font(.headline)
                        } else {
                            Text("Unbekannt")
                                .font(.headline)
                        }
                        if let vereinID = contract.vereinID,
                           let club = clubs.first(where: { $0.name == vereinID }) {
                            Text(club.name) // Ohne "Verein:"
                        } else {
                            Text("Unbekannt")
                        }
                        if let endDatum = contract.endDatum {
                            Text("Ende: \(dateFormatter.string(from: endDatum))")
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteContract(contract)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            isEditing = true
                            newContract = contract
                            showingAddContract = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Vertrag bearbeiten" : "Vertragsübersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Neuen Vertrag anlegen") {
                        if authManager.isLoggedIn {
                            showingAddContract = true
                            isEditing = false
                            newContract = Contract(
                                id: nil,
                                clientID: nil,
                                vereinID: nil,
                                startDatum: Date(),
                                endDatum: nil,
                                gehalt: nil,
                                vertragsdetails: nil
                            )
                        } else {
                            errorMessage = "Du musst angemeldet sein, um einen neuen Vertrag anzulegen."
                        }
                    }
                    .disabled(!authManager.isLoggedIn)
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .sheet(isPresented: $showingAddContract) {
                AddContractView(
                    contract: $newContract,
                    isEditing: isEditing,
                    onSave: { contract in
                        Task {
                            if authManager.isLoggedIn {
                                if isEditing {
                                    await updateContract(contract)
                                } else {
                                    await createContract(contract)
                                }
                            } else {
                                await MainActor.run {
                                    errorMessage = "Du musst angemeldet sein, um den Vertrag zu speichern."
                                }
                            }
                            await MainActor.run {
                                showingAddContract = false
                                isEditing = false
                                newContract = Contract(
                                    id: nil,
                                    clientID: nil,
                                    vereinID: nil,
                                    startDatum: Date(),
                                    endDatum: nil,
                                    gehalt: nil,
                                    vertragsdetails: nil
                                )
                            }
                        }
                    },
                    onCancel: {
                        showingAddContract = false
                        isEditing = false
                        newContract = Contract(
                            id: nil,
                            clientID: nil,
                            vereinID: nil,
                            startDatum: Date(),
                            endDatum: nil,
                            gehalt: nil,
                            vertragsdetails: nil
                        )
                    }
                )
            }
            .task {
                await loadContracts()
                await loadClients()
                await loadClubs()
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadContracts() async {
        do {
            let loadedContracts = try await FirestoreManager.shared.getContracts()
            await MainActor.run {
                contracts = loadedContracts
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Verträge: \(error.localizedDescription)"
            }
        }
    }

    private func loadClients() async {
        do {
            let loadedClients = try await FirestoreManager.shared.getClients()
            await MainActor.run {
                clients = loadedClients
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Klienten: \(error.localizedDescription)"
            }
        }
    }

    private func loadClubs() async {
        do {
            let loadedClubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                clubs = loadedClubs
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }

    private func createContract(_ contract: Contract) async {
        do {
            try await FirestoreManager.shared.createContract(contract: contract)
            await loadContracts()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Hinzufügen des Vertrags: \(error.localizedDescription)"
            }
        }
    }

    private func updateContract(_ contract: Contract) async {
        do {
            try await FirestoreManager.shared.updateContract(contract: contract)
            await loadContracts()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Aktualisieren des Vertrags: \(error.localizedDescription)"
            }
        }
    }

    private func deleteContract(_ contract: Contract) async {
        guard let id = contract.id else { return }
        do {
            try await FirestoreManager.shared.deleteContract(contractID: id)
            await loadContracts()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen des Vertrags: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContractListView()
        .environmentObject(AuthManager())
}
