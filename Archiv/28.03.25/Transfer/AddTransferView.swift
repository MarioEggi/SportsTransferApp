import SwiftUI

struct AddTransferView: View {
    let isEditing: Bool
    let initialTransfer: Transfer?
    let onSave: (Transfer) -> Void
    let onCancel: () -> Void

    @State private var clientID: String? = nil
    @State private var vonVereinID: String? = nil
    @State private var zuVereinID: String? = nil
    @State private var datum: Date = Date()
    @State private var ablösesumme: String = ""
    @State private var isAblösefrei: Bool = false
    @State private var transferdetails: String = ""
    @State private var clients: [Client] = []
    @State private var clubs: [Club] = []
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transferdetails")) {
                    Picker("Klient", selection: $clientID) {
                        Text("Kein Klient").tag(String?.none)
                        ForEach(clients) { client in
                            Text("\(client.vorname) \(client.name)").tag(client.id as String?)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Von Verein", selection: $vonVereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubs) { club in
                            Text(club.name).tag(club.name as String?)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Zu Verein", selection: $zuVereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubs) { club in
                            Text(club.name).tag(club.name as String?)
                        }
                    }
                    .pickerStyle(.menu)

                    DatePicker("Datum", selection: $datum, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    Toggle("Ablösefrei", isOn: $isAblösefrei)

                    if !isAblösefrei {
                        TextField("Ablösesumme (€)", text: $ablösesumme)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Transferdetails", text: $transferdetails)
                }
            }
            .navigationTitle(isEditing ? "Transfer bearbeiten" : "Neuer Transfer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveTransfer()
                    }
                    .disabled(clientID == nil || (vonVereinID == nil && zuVereinID == nil))
                }
            }
            .task {
                await loadClientsAndClubs()
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

    private func loadClientsAndClubs() async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                clients = loadedClients
                clubs = loadedClubs

                if let initial = initialTransfer {
                    clientID = initial.clientID
                    vonVereinID = initial.vonVereinID
                    zuVereinID = initial.zuVereinID
                    datum = initial.datum
                    ablösesumme = initial.ablösesumme != nil ? String(initial.ablösesumme!) : ""
                    isAblösefrei = initial.isAblösefrei
                    transferdetails = initial.transferdetails ?? ""
                }
            }
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
        }
    }

    private func saveTransfer() {
        let transfer = Transfer(
            id: initialTransfer?.id,
            clientID: clientID,
            vonVereinID: vonVereinID,
            zuVereinID: zuVereinID,
            datum: datum,
            ablösesumme: isAblösefrei ? nil : Double(ablösesumme),
            isAblösefrei: isAblösefrei,
            transferdetails: transferdetails.isEmpty ? nil : transferdetails
        )
        onSave(transfer)
    }
}

#Preview {
    AddTransferView(
        isEditing: false,
        initialTransfer: nil,
        onSave: { _ in },
        onCancel: {}
    )
}
