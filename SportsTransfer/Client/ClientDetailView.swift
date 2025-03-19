import SwiftUI
import FirebaseFirestore

struct ClientDetailView: View {
    let client: Client
    @State private var contracts: [Contract] = []
    @State private var transfers: [Transfer] = []
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Begrüßung
                HStack {
                    VStack(alignment: .leading) {
                        // Aufteilung des Ausdrucks in Zeile 10
                        let welcomeMessage = "Willkommen, \(client.vorname) \(client.name)"
                        Text(welcomeMessage)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding()

                // Übersicht
                ScrollView {
                    VStack(spacing: 20) {
                        // Klienteninformationen
                        Section(header: Text("Meine Daten").font(.headline)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Typ: \(client.typ)")
                                if let lizenz = client.lizenz {
                                    Text("Lizenz: \(lizenz)")
                                }
                                if let positions = client.positionFeld, !positions.isEmpty {
                                    Text("Positionen: \(positions.joined(separator: ", "))")
                                }
                                if let vereinID = client.vereinID {
                                    Text("Verein: \(vereinID)")
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        // Verträge
                        Section(header: Text("Meine Verträge").font(.headline)) {
                            if contracts.isEmpty {
                                Text("Keine Verträge vorhanden.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(contracts) { contract in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Verein: \(contract.vereinID ?? "Kein Verein")")
                                        Text("Start: \(dateFormatter.string(from: contract.startDatum))")
                                        Text("Ende: \(contract.endDatum.map { dateFormatter.string(from: $0) } ?? "Kein Ende")")
                                        Text("Gehalt: \(contract.gehalt.map { String(format: "%.2f €", $0) } ?? "Keine")")
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }

                        // Transfers
                        Section(header: Text("Meine Transfers").font(.headline)) {
                            if transfers.isEmpty {
                                Text("Keine Transfers vorhanden.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(transfers) { transfer in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Von: \(transfer.vonVereinID ?? "Kein Verein")")
                                        Text("Zu: \(transfer.zuVereinID ?? "Kein Verein")")
                                        Text("Datum: \(dateFormatter.string(from: transfer.datum))")
                                        Text("Ablösesumme: \(transfer.ablösesumme.map { String(format: "%.2f €", $0) } ?? (transfer.isAblösefrei ? "Ablösefrei" : "Keine"))")
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Klientendetails")
            .task {
                await loadClientData()
            }
        }
    }

    private func loadClientData() async {
        do {
            let loadedContracts = try await FirestoreManager.shared.getContracts()
            let loadedTransfers = try await FirestoreManager.shared.getTransfers()
            await MainActor.run {
                self.contracts = loadedContracts.filter { $0.clientID == client.id }
                self.transfers = loadedTransfers.filter { $0.clientID == client.id }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
            }
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    ClientDetailView(client: Client(
        id: "1",
        typ: "Spieler",
        name: "Müller",
        vorname: "Hans",
        geschlecht: "männlich",
        vereinID: "Verein1",
        positionFeld: ["Stürmer"]
    ))
        .environmentObject(AuthManager())
}
