import SwiftUI
import FirebaseFirestore

struct ContractListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ContractViewModel()
    @State private var showingAddContract = false
    @State private var isEditing = false
    @State private var newContract: Contract = defaultContract()
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            contractList
                .navigationTitle(isEditing ? "Vertrag bearbeiten" : "Vertragsübersicht")
                .foregroundColor(.white)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if authManager.userRole == .mitarbeiter {
                            Button("Neuen Vertrag anlegen") {
                                if authManager.isLoggedIn {
                                    showingAddContract = true
                                    isEditing = false
                                    resetNewContract()
                                } else {
                                    errorMessage = "Du musst angemeldet sein."
                                }
                            }
                            .foregroundColor(.white)
                            .disabled(!authManager.isLoggedIn)
                        }
                    }
                }
                .sheet(isPresented: $showingAddContract) {
                    AddContractView(
                        contract: $newContract,
                        isEditing: isEditing,
                        onSave: { contract in
                            Task {
                                await viewModel.saveContract(contract)
                                await MainActor.run {
                                    showingAddContract = false
                                    isEditing = false
                                    resetNewContract()
                                }
                            }
                        },
                        onCancel: {
                            showingAddContract = false
                            isEditing = false
                            resetNewContract()
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
                .task {
                    await viewModel.loadContracts()
                }
                .background(Color.black)
        }
    }

    private var contractList: some View {
        List {
            ForEach(viewModel.contracts) { contract in
                ContractRowView(
                    contract: contract,
                    viewModel: viewModel,
                    onDelete: {
                        if authManager.userRole == .mitarbeiter {
                            Task { await viewModel.deleteContract(contract) }
                        }
                    },
                    onEdit: {
                        if authManager.userRole == .mitarbeiter {
                            isEditing = true
                            newContract = contract
                            showingAddContract = true
                        }
                    },
                    isLast: contract == viewModel.contracts.last
                )
                .listRowBackground(Color.gray.opacity(0.2))
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .tint(.white)
                    .listRowBackground(Color.black)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private func resetNewContract() {
        newContract = ContractListView.defaultContract()
    }

    private static func defaultContract() -> Contract {
        Contract(
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

struct ContractRowView: View {
    let contract: Contract
    let viewModel: ContractViewModel
    let onDelete: () -> Void
    let onEdit: () -> Void
    let isLast: Bool
    @EnvironmentObject var authManager: AuthManager
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading) {
            clientText
            vereinText
            endDatumText
        }
        .swipeActions {
            if authManager.userRole == .mitarbeiter {
                Button(role: .destructive, action: onDelete) {
                    Label("Löschen", systemImage: "trash")
                        .foregroundColor(.white)
                }
                Button(action: onEdit) {
                    Label("Bearbeiten", systemImage: "pencil")
                        .foregroundColor(.white)
                }
                .tint(.blue)
            }
        }
        .onAppear {
            if isLast {
                Task { await viewModel.loadContracts(loadMore: true) }
            }
        }
    }

    private var clientText: some View {
        if let clientID = contract.clientID,
           let client = viewModel.clients.first(where: { $0.id == clientID }) {
            Text("\(client.vorname) \(client.name)")
                .font(.headline)
                .foregroundColor(.white)
        } else {
            Text("Unbekannt")
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private var vereinText: some View {
        if let vereinID = contract.vereinID,
           let club = viewModel.clubs.first(where: { $0.name == vereinID }) {
            Text(club.name)
                .foregroundColor(.white)
        } else {
            Text("Unbekannt")
                .foregroundColor(.white)
        }
    }

    private var endDatumText: some View {
        Group {
            if let endDatum = contract.endDatum {
                Text("Ende: \(dateFormatter.string(from: endDatum))")
                    .foregroundColor(.white)
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    ContractListView()
        .environmentObject(AuthManager())
}
