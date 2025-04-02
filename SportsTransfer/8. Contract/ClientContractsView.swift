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

    // Farben für das dunkle Design
    private let backgroundColor = Color(hex: "#1C2526")
    private let cardBackgroundColor = Color(hex: "#2A3439")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    HStack {
                        Text("Verträge von \(client.vorname) \(client.name)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        Button(action: {
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
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if contracts.isEmpty {
                            Text("Keine Verträge vorhanden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
                            ForEach(contracts) { contract in
                                NavigationLink(destination: ContractDetailView(contract: contract)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(client.vorname) \(client.name)")
                                            .font(.headline)
                                            .foregroundColor(textColor)
                                        if let vereinID = contract.vereinID {
                                            Text(vereinID)
                                                .font(.caption)
                                                .foregroundColor(secondaryTextColor)
                                        }
                                        if let endDatum = contract.endDatum {
                                            Text("Ende: \(dateFormatter.string(from: endDatum))")
                                                .font(.caption)
                                                .foregroundColor(secondaryTextColor)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                                .swipeActions {
                                    Button {
                                        isEditing = true
                                        newContract = contract
                                        showingAddContract = true
                                    } label: {
                                        Label("Bearbeiten", systemImage: "pencil")
                                            .foregroundColor(.white)
                                    }
                                    .tint(.blue)
                                    Button(role: .destructive) {
                                        Task { await deleteContract(contract) }
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                            .foregroundColor(.white)
                                    }
                                }
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(cardBackgroundColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                        .padding(.vertical, 2)
                                )
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(backgroundColor)
                    .padding(.horizontal)
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
                    Alert(
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
                            errorMessage = ""
                        }
                    )
                }
                .task {
                    await loadContracts()
                }
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
            let (loadedContracts, _) = try await FirestoreManager.shared.getContracts(lastDocument: nil, limit: 1000)
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
