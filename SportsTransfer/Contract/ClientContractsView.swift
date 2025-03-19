import SwiftUI
import FirebaseFirestore

struct ClientContractsView: View {
    let client: Client
    @State private var contracts: [Contract] = []
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
                    NavigationLink(destination: ContractDetailView(contract: contract)) {
                        VStack(alignment: .leading) {
                            Text("\(client.vorname) \(client.name)")
                                .font(.headline)
                            if let vereinID = contract.vereinID {
                                Text(vereinID)
                            }
                            if let endDatum = contract.endDatum {
                                Text("Ende: \(dateFormatter.string(from: endDatum))")
                            }
                        }
                    }
                    .swipeActions {
                        Button {
                            isEditing = true
                            newContract = contract
                            showingAddContract = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            Task {
                                await deleteContract(contract)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Verträge von \(client.vorname) \(client.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Neuen Vertrag anlegen") {
                        showingAddContract = true
                        isEditing = false
                        newContract = Contract(
                            id: nil,
                            clientID: client.id,
                            vereinID: nil,
                            startDatum: Date(),
                            endDatum: nil,
                            gehalt: nil,
                            vertragsdetails: nil
                        )
                    }
                }
            }
            .sheet(isPresented: $showingAddContract) {
                AddContractView(
                    contract: $newContract,
                    isEditing: isEditing,
                    onSave: { contract in
                        Task {
                            if isEditing {
                                await updateContract(contract)
                            } else {
                                await createContract(contract)
                            }
                            await MainActor.run {
                                showingAddContract = false
                                isEditing = false
                                newContract = Contract(
                                    id: nil,
                                    clientID: client.id,
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
                        Task {
                            await MainActor.run {
                                showingAddContract = false
                                isEditing = false
                                newContract = Contract(
                                    id: nil,
                                    clientID: client.id,
                                    vereinID: nil,
                                    startDatum: Date(),
                                    endDatum: nil,
                                    gehalt: nil,
                                    vertragsdetails: nil
                                )
                            }
                        }
                    }
                )
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .task {
                await loadContracts()
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func loadContracts() async {
        guard let clientID = client.id else { return }
        do {
            let loadedContracts = try await FirestoreManager.shared.getContracts()
            await MainActor.run {
                contracts = loadedContracts.filter { $0.clientID == clientID }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Verträge: \(error.localizedDescription)"
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
    ClientContractsView(client: Client(
        typ: "Spieler",
        name: "Mustermann",
        vorname: "Max",
        geschlecht: "männlich",
        vereinID: nil
    ))
    .environmentObject(AuthManager())
}
