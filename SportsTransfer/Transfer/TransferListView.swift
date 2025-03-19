import SwiftUI
import FirebaseFirestore

struct TransferListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var transfers: [Transfer] = []
    @State private var clients: [Client] = []
    @State private var clubs: [Club] = []
    @State private var showingAddTransfer = false
    @State private var isEditing = false
    @State private var errorMessage: String = ""
    @State private var selectedTransfer: Transfer? // Für Bearbeitung

    var body: some View {
        NavigationStack {
            List {
                ForEach(transfers) { transfer in
                    VStack(alignment: .leading) {
                        if let clientID = transfer.clientID,
                           let client = clients.first(where: { $0.id == clientID }) {
                            Text("Klient: \(client.vorname) \(client.name)")
                                .font(.headline)
                        } else {
                            Text("Klient: Unbekannt")
                                .font(.headline)
                        }
                        if let vonVereinID = transfer.vonVereinID,
                           let vonClub = clubs.first(where: { $0.name == vonVereinID }) {
                            Text("Von: \(vonClub.name)")
                        } else {
                            Text("Von: Unbekannt")
                        }
                        if let zuVereinID = transfer.zuVereinID,
                           let zuClub = clubs.first(where: { $0.name == zuVereinID }) {
                            Text("Zu: \(zuClub.name)")
                        } else {
                            Text("Zu: Unbekannt")
                        }
                        Text("Datum: \(dateFormatter.string(from: transfer.datum))")
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await deleteTransfer(transfer)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            isEditing = true
                            selectedTransfer = transfer
                            showingAddTransfer = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Transfer bearbeiten" : "Transferübersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Neuen Transfer anlegen") {
                        if authManager.isLoggedIn {
                            showingAddTransfer = true
                            isEditing = false
                            selectedTransfer = nil
                        } else {
                            errorMessage = "Du musst angemeldet sein, um einen neuen Transfer anzulegen."
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
            .sheet(isPresented: $showingAddTransfer) {
                AddTransferView(
                    isEditing: isEditing,
                    initialTransfer: selectedTransfer,
                    onSave: { transfer in
                        Task {
                            if authManager.isLoggedIn {
                                if isEditing {
                                    await updateTransfer(transfer)
                                } else {
                                    await createTransfer(transfer)
                                }
                            } else {
                                await MainActor.run {
                                    errorMessage = "Du musst angemeldet sein, um den Transfer zu speichern."
                                }
                            }
                            await MainActor.run {
                                showingAddTransfer = false
                                isEditing = false
                            }
                        }
                    },
                    onCancel: {
                        showingAddTransfer = false
                        isEditing = false
                    }
                )
            }
            .task {
                await loadTransfers()
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

    private func loadTransfers() async {
        do {
            let loadedTransfers = try await FirestoreManager.shared.getTransfers()
            await MainActor.run {
                transfers = loadedTransfers
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Transfers: \(error.localizedDescription)"
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

    private func createTransfer(_ transfer: Transfer) async {
        do {
            try await FirestoreManager.shared.createTransfer(transfer: transfer)
            await loadTransfers()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Hinzufügen des Transfers: \(error.localizedDescription)"
            }
        }
    }

    private func updateTransfer(_ transfer: Transfer) async {
        do {
            try await FirestoreManager.shared.updateTransfer(transfer: transfer)
            await loadTransfers()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Aktualisieren des Transfers: \(error.localizedDescription)"
            }
        }
    }

    private func deleteTransfer(_ transfer: Transfer) async {
        guard let id = transfer.id else { return }
        do {
            try await FirestoreManager.shared.deleteTransfer(transferID: id)
            await loadTransfers()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Löschen des Transfers: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    TransferListView()
        .environmentObject(AuthManager())
}
