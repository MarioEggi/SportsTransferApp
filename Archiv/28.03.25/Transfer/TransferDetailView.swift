import SwiftUI
import FirebaseFirestore

struct TransferDetailView: View {
    let transfer: Transfer
    @EnvironmentObject var authManager: AuthManager
    @State private var showingEditSheet = false
    @State private var client: Client? = nil
    @State private var vonClub: Club? = nil
    @State private var zuClub: Club? = nil
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Transferdetails")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()

                VStack(alignment: .leading, spacing: 10) {
                    if let client = client {
                        Text("Klient: \(client.vorname) \(client.name)")
                            .font(.headline)
                    }
                    if let vonClub = vonClub {
                        Text("Von Verein: \(vonClub.name)")
                            .font(.headline)
                    }
                    if let zuClub = zuClub {
                        Text("Zu Verein: \(zuClub.name)")
                            .font(.headline)
                    }
                    Text("Datum: \(dateFormatter.string(from: transfer.datum))")
                    if let ablösesumme = transfer.ablösesumme, !transfer.isAblösefrei {
                        Text("Ablösesumme: \(String(format: "%.2f €", ablösesumme))")
                    } else if transfer.isAblösefrei {
                        Text("Ablösefrei")
                            .foregroundColor(.green)
                    }
                    if let transferdetails = transfer.transferdetails {
                        Text("Details: \(transferdetails)")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                if authManager.userRole == .mitarbeiter {
                    Button("Bearbeiten") {
                        showingEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Transfer")
            .task {
                await loadClientAndClubs()
            }
            .sheet(isPresented: $showingEditSheet) {
                AddTransferView(
                    isEditing: true,
                    initialTransfer: transfer,
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
                    title: Text("Fehler"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK")) {
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

    private func loadClientAndClubs() async {
        do {
            if let clientID = transfer.clientID {
                let (clients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
                await MainActor.run {
                    self.client = clients.first { $0.id == clientID }
                }
            }
            if let vonVereinID = transfer.vonVereinID {
                let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
                await MainActor.run {
                    self.vonClub = clubs.first { $0.name == vonVereinID }
                }
            }
            if let zuVereinID = transfer.zuVereinID {
                let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
                await MainActor.run {
                    self.zuClub = clubs.first { $0.name == zuVereinID }
                }
            }
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
        }
    }
}

#Preview {
    TransferDetailView(transfer: Transfer(
        id: "1",
        clientID: "client1",
        vonVereinID: "Verein1",
        zuVereinID: "Verein2",
        datum: Date(),
        ablösesumme: 5000000.0,
        isAblösefrei: false,
        transferdetails: "Standardtransfer"
    ))
    .environmentObject(AuthManager())
}
