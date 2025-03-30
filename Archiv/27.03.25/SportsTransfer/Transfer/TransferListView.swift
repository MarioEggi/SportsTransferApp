import SwiftUI
import FirebaseFirestore

struct TransferListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = TransferViewModel()
    @State private var showingAddTransfer = false
    @State private var isEditing = false
    @State private var selectedTransfer: Transfer?
    @State private var errorMessage = ""
    @State private var filterDate: Date? = nil
    @State private var filterClientID: String? = nil

    var filteredTransfers: [Transfer] {
        var result = viewModel.transfers
        if let date = filterDate {
            result = result.filter { Calendar.current.isDate($0.datum, inSameDayAs: date) }
        }
        if let clientID = filterClientID {
            result = result.filter { $0.clientID == clientID }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                DatePicker("Filter nach Datum", selection: Binding(get: { filterDate ?? Date() }, set: { filterDate = $0 }), displayedComponents: .date)
                    .padding(.horizontal)
                Picker("Filter nach Klient", selection: $filterClientID) {
                    Text("Alle").tag(String?.none)
                    ForEach(viewModel.clients) { client in
                        Text("\(client.vorname) \(client.name)").tag(client.id as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                transferList
            }
            .navigationTitle(isEditing ? "Transfer bearbeiten" : "Transferübersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authManager.userRole == .mitarbeiter {
                        Button("Neuen Transfer anlegen") {
                            if authManager.isLoggedIn {
                                showingAddTransfer = true
                                isEditing = false
                                selectedTransfer = nil
                            } else {
                                errorMessage = "Du musst angemeldet sein."
                            }
                        }
                        .disabled(!authManager.isLoggedIn)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransfer) {
                AddTransferView(
                    isEditing: isEditing,
                    initialTransfer: selectedTransfer,
                    onSave: { transfer in
                        Task {
                            await viewModel.saveTransfer(transfer)
                            await MainActor.run {
                                showingAddTransfer = false
                                isEditing = false
                                selectedTransfer = nil
                            }
                        }
                    },
                    onCancel: {
                        showingAddTransfer = false
                        isEditing = false
                        selectedTransfer = nil
                    }
                )
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = ""
                    }
                )
            }
            .task {
                await viewModel.loadTransfers()
            }
        }
    }

    private var transferList: some View {
        List {
            ForEach(filteredTransfers) { transfer in
                TransferRowView(
                    transfer: transfer,
                    viewModel: viewModel,
                    onDelete: {
                        if authManager.userRole == .mitarbeiter {
                            Task { await viewModel.deleteTransfer(transfer) }
                        }
                    },
                    onEdit: {
                        if authManager.userRole == .mitarbeiter {
                            isEditing = true
                            selectedTransfer = transfer
                            showingAddTransfer = true
                        }
                    },
                    isLast: transfer == viewModel.transfers.last
                )
            }
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct TransferRowView: View {
    let transfer: Transfer
    let viewModel: TransferViewModel
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
            vonVereinText
            zuVereinText
            Text("Datum: \(dateFormatter.string(from: transfer.datum))")
        }
        .swipeActions {
            if authManager.userRole == .mitarbeiter {
                Button(role: .destructive, action: onDelete) {
                    Label("Löschen", systemImage: "trash")
                }
                Button(action: onEdit) {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
        .onAppear {
            if isLast {
                Task { await viewModel.loadTransfers(loadMore: true) }
            }
        }
    }

    private var clientText: some View {
        if let clientID = transfer.clientID,
           let client = viewModel.clients.first(where: { $0.id == clientID }) {
            return Text("Klient: \(client.vorname) \(client.name)")
                .font(.headline)
                .eraseToAnyView()
        } else {
            return Text("Klient: Unbekannt")
                .font(.headline)
                .eraseToAnyView()
        }
    }

    private var vonVereinText: some View {
        if let vonVereinID = transfer.vonVereinID,
           let vonClub = viewModel.clubs.first(where: { $0.name == vonVereinID }) {
            return Text("Von: \(vonClub.name)")
                .eraseToAnyView()
        } else {
            return Text("Von: Unbekannt")
                .eraseToAnyView()
        }
    }

    private var zuVereinText: some View {
        if let zuVereinID = transfer.zuVereinID,
           let zuClub = viewModel.clubs.first(where: { $0.name == zuVereinID }) {
            return Text("Zu: \(zuClub.name)")
                .eraseToAnyView()
        } else {
            return Text("Zu: Unbekannt")
                .eraseToAnyView()
        }
    }
}

#Preview {
    TransferListView()
        .environmentObject(AuthManager())
}
