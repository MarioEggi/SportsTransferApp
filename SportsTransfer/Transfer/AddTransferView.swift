import SwiftUI
import FirebaseFirestore

struct AddTransferView: View {
    let isEditing: Bool
    let initialTransfer: Transfer?
    let onSave: (Transfer) -> Void
    let onCancel: () -> Void

    @State private var selectedClient: Client? = nil
    @State private var selectedVonVerein: Club? = nil
    @State private var selectedZuVerein: Club? = nil
    @State private var datum: Date = Date()
    @State private var ablösesumme: Double? = nil // Umbenannt von gebuehr
    @State private var isAblösefrei: Bool = false // Neues Feld für ablösefrei
    @State private var transferdetails: String? = nil
    @State private var clients: [Client] = []
    @State private var clubs: [Club] = []
    @State private var showingAddClubSheet = false
    @State private var showingContractsSheet = false // Für die Vertragsübersicht
    @State private var newClub = Club(name: "")
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transferdaten")) {
                    // Klient Picker mit "Verträge ansehen"-Button
                    VStack {
                        Picker("Klient", selection: $selectedClient) {
                            Text("Kein Klient ausgewählt").tag(Client?.none)
                            ForEach(clients) { client in
                                Text("\(client.vorname) \(client.name)")
                                    .tag(client as Client?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        if selectedClient != nil {
                            Button(action: { showingContractsSheet = true }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.blue)
                                    Text("Verträge ansehen")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }

                    // Von Verein Picker mit "Neuer Verein"-Button
                    VStack {
                        Picker("Von Verein", selection: $selectedVonVerein) {
                            Text("Kein Verein ausgewählt").tag(Club?.none)
                            ForEach(clubs) { club in
                                Text(club.name).tag(club as Club?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button(action: { showingAddClubSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("Neuer Verein")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Zu Verein Picker mit "Neuer Verein"-Button
                    VStack {
                        Picker("Zu Verein", selection: $selectedZuVerein) {
                            Text("Kein Verein ausgewählt").tag(Club?.none)
                            ForEach(clubs) { club in
                                Text(club.name).tag(club as Club?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Button(action: { showingAddClubSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                Text("Neuer Verein")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }

                    DatePicker("Datum", selection: $datum, displayedComponents: .date)
                    
                    // Ablösesumme und Ablösefrei-Checkbox
                    TextField("Ablösesumme", value: $ablösesumme, format: .number)
                        .disabled(isAblösefrei) // Deaktiviert, wenn ablösefrei
                        .foregroundColor(isAblösefrei ? .gray : .primary)
                    
                    Toggle("Ablösefrei", isOn: $isAblösefrei)
                        .onChange(of: isAblösefrei) { newValue in
                            if newValue {
                                ablösesumme = nil // Setze Ablösesumme auf nil, wenn ablösefrei
                            }
                        }

                    TextField("Transferdetails", text: Binding(
                        get: { transferdetails ?? "" },
                        set: { transferdetails = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle(isEditing ? "Transfer bearbeiten" : "Transfer anlegen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let transfer = Transfer(
                            id: initialTransfer?.id,
                            clientID: selectedClient?.id,
                            vonVereinID: selectedVonVerein?.name,
                            zuVereinID: selectedZuVerein?.name,
                            datum: datum,
                            ablösesumme: isAblösefrei ? nil : ablösesumme,
                            isAblösefrei: isAblösefrei,
                            transferdetails: transferdetails
                        )
                        onSave(transfer)
                    }
                    .disabled(selectedClient == nil || selectedVonVerein == nil || selectedZuVerein == nil)
                }
            }
            .sheet(isPresented: $showingAddClubSheet) {
                AddClubView(
                    club: $newClub,
                    onSave: { updatedClub in
                        Task {
                            do {
                                try await FirestoreManager.shared.createClub(club: updatedClub)
                                await loadClubs()
                                await MainActor.run {
                                    newClub = Club(name: "")
                                }
                            } catch {
                                await MainActor.run {
                                    errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                                }
                            }
                            await MainActor.run {
                                showingAddClubSheet = false
                            }
                        }
                    },
                    onCancel: {
                        Task {
                            await MainActor.run {
                                newClub = Club(name: "")
                                showingAddClubSheet = false
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showingContractsSheet) {
                if let client = selectedClient {
                    ClientContractsView(client: client)
                } else {
                    EmptyView() // Fallback, falls kein Client ausgewählt ist
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .task {
                await loadClients()
                await loadClubs()
                if let transfer = initialTransfer {
                    // Setze die initialen Werte bei Bearbeitung
                    if let clientID = transfer.clientID {
                        let loadedClients = try? await FirestoreManager.shared.getClients()
                        await MainActor.run {
                            selectedClient = loadedClients?.first { $0.id == clientID }
                        }
                    }
                    if let vonVereinID = transfer.vonVereinID {
                        let loadedClubs = try? await FirestoreManager.shared.getClubs()
                        await MainActor.run {
                            selectedVonVerein = loadedClubs?.first { $0.name == vonVereinID }
                        }
                    }
                    if let zuVereinID = transfer.zuVereinID {
                        let loadedClubs = try? await FirestoreManager.shared.getClubs()
                        await MainActor.run {
                            selectedZuVerein = loadedClubs?.first { $0.name == zuVereinID }
                        }
                    }
                    datum = transfer.datum
                    ablösesumme = transfer.ablösesumme
                    isAblösefrei = transfer.isAblösefrei
                    transferdetails = transfer.transferdetails
                }
            }
        }
    }

    private func loadClients() async {
        do {
            let loadedClients = try await FirestoreManager.shared.getClients()
            await MainActor.run {
                self.clients = loadedClients
                // Setze den ausgewählten Klienten bei Bearbeitung
                if let clientID = initialTransfer?.clientID {
                    self.selectedClient = loadedClients.first { $0.id == clientID }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der Klienten: \(error.localizedDescription)"
            }
        }
    }

    private func loadClubs() async {
        do {
            let loadedClubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                self.clubs = loadedClubs
                // Setze die ausgewählten Vereine bei Bearbeitung
                if let vonVereinID = initialTransfer?.vonVereinID {
                    self.selectedVonVerein = loadedClubs.first { $0.name == vonVereinID }
                }
                if let zuVereinID = initialTransfer?.zuVereinID {
                    self.selectedZuVerein = loadedClubs.first { $0.name == zuVereinID }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AddTransferView(
        isEditing: false,
        initialTransfer: nil,
        onSave: { _ in },
        onCancel: {}
    )
    .environmentObject(AuthManager())
}
