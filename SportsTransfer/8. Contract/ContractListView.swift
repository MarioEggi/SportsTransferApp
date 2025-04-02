import SwiftUI
import FirebaseFirestore

struct ContractListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ContractViewModel()
    @State private var showingAddContract = false
    @State private var isEditing = false
    @State private var newContract: Contract = defaultContract()
    @State private var errorMessage = ""

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
                        Text(isEditing ? "Vertrag bearbeiten" : "Verträge")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Spacer()
                        if authManager.userRole == .mitarbeiter {
                            Button(action: {
                                if authManager.isLoggedIn {
                                    showingAddContract = true
                                    isEditing = false
                                    resetNewContract()
                                } else {
                                    errorMessage = "Du musst angemeldet sein."
                                }
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(accentColor)
                            }
                            .disabled(!authManager.isLoggedIn)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    List {
                        if viewModel.contracts.isEmpty && !viewModel.isLoading {
                            Text("Keine Verträge gefunden.")
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(backgroundColor)
                        } else {
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
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .tint(accentColor)
                                    .listRowBackground(backgroundColor)
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
                        title: Text("Fehler").foregroundColor(textColor),
                        message: Text(errorMessage).foregroundColor(secondaryTextColor),
                        dismissButton: .default(Text("OK").foregroundColor(accentColor)) {
                            errorMessage = ""
                        }
                    )
                }
                .task {
                    await viewModel.loadContracts()
                }
            }
        }
    }

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

    // Farben für das dunkle Design
    private let textColor = Color(hex: "#E0E0E0")
    private let secondaryTextColor = Color(hex: "#B0BEC5")
    private let accentColor = Color(hex: "#00C4B4")

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                clientText
                vereinText
                endDatumText
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
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
                .foregroundColor(textColor)
        } else {
            Text("Unbekannt")
                .font(.headline)
                .foregroundColor(textColor)
        }
    }

    private var vereinText: some View {
        if let vereinID = contract.vereinID,
           let club = viewModel.clubs.first(where: { $0.name == vereinID }) {
            Text(club.name)
                .font(.caption)
                .foregroundColor(secondaryTextColor)
        } else {
            Text("Unbekannt")
                .font(.caption)
                .foregroundColor(secondaryTextColor)
        }
    }

    private var endDatumText: some View {
        Group {
            if let endDatum = contract.endDatum {
                Text("Ende: \(dateFormatter.string(from: endDatum))")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
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
