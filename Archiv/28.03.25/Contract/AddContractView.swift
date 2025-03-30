import SwiftUI
import FirebaseFirestore

struct AddContractView: View {
    @Binding var contract: Contract
    var isEditing: Bool
    var onSave: (Contract) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedClient: Client? = nil
    @State private var selectedVerein: Club? = nil
    @State private var startDatum: Date = Date()
    @State private var endDatum: Date? = nil
    @State private var gehalt: Double? = nil
    @State private var vertragsdetails: String? = nil
    @State private var clients: [Client] = []
    @State private var clubs: [Club] = []
    @State private var showingAddClubSheet = false
    @State private var newClub = Club(name: "")
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                if authManager.userRole == .mitarbeiter {
                    Section(header: Text("Vertragsdaten")) {
                        Picker("Klient", selection: $selectedClient) {
                            Text("Kein Klient ausgewählt").tag(Client?.none)
                            ForEach(clients) { client in
                                Text("\(client.vorname) \(client.name)")
                                    .tag(client as Client?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        VStack {
                            Picker("Verein", selection: $selectedVerein) {
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

                        DatePicker("Startdatum", selection: $startDatum, displayedComponents: .date)
                        DatePicker("Enddatum", selection: Binding(
                            get: { endDatum ?? Date() },
                            set: { endDatum = $0 }
                        ), displayedComponents: .date)
                        TextField("Gehalt (€)", value: $gehalt, format: .number)
                        TextField("Vertragsdetails", text: Binding(
                            get: { vertragsdetails ?? "" },
                            set: { vertragsdetails = $0.isEmpty ? nil : $0 }
                        ))
                    }
                } else {
                    Text("Nur Mitarbeiter können Verträge bearbeiten.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle(isEditing ? "Vertrag bearbeiten" : "Vertrag anlegen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if authManager.userRole == .mitarbeiter {
                        Button("Speichern") {
                            if validateInputs() {
                                contract.clientID = selectedClient?.id
                                contract.vereinID = selectedVerein?.name
                                contract.startDatum = startDatum
                                contract.endDatum = endDatum
                                contract.gehalt = gehalt
                                contract.vertragsdetails = vertragsdetails
                                onSave(contract)
                            }
                        }
                        .disabled(selectedClient == nil || selectedVerein == nil)
                    }
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
                                selectedVerein = clubs.first { $0.name == updatedClub.name }
                                await MainActor.run {
                                    newClub = Club(name: "")
                                }
                            } catch {
                                await MainActor.run {
                                    errorMessage = "Fehler beim Speichern des Vereins: \(error.localizedDescription)"
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
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
            .task {
                await loadClients()
                await loadClubs()
                if isEditing {
                    startDatum = contract.startDatum
                    endDatum = contract.endDatum
                    gehalt = contract.gehalt
                    vertragsdetails = contract.vertragsdetails
                    if let clientID = contract.clientID {
                        selectedClient = clients.first { $0.id == clientID }
                    }
                    if let vereinID = contract.vereinID {
                        selectedVerein = clubs.first { $0.name == vereinID }
                    }
                }
            }
        }
    }

    private func loadClients() async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(limit: 1000)
            await MainActor.run {
                self.clients = loadedClients
                if let clientID = contract.clientID {
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
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                self.clubs = loadedClubs
                if let vereinID = contract.vereinID {
                    self.selectedVerein = loadedClubs.first { $0.name == vereinID }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }

    private func validateInputs() -> Bool {
        if let endDatum = endDatum, endDatum < startDatum {
            errorMessage = "Das Enddatum darf nicht vor dem Startdatum liegen."
            return false
        }
        if let gehalt = gehalt, gehalt < 0 {
            errorMessage = "Das Gehalt darf nicht negativ sein."
            return false
        }
        return true
    }
}

#Preview {
    AddContractView(
        contract: .constant(Contract(
            id: nil,
            clientID: nil,
            vereinID: nil,
            startDatum: Date(),
            endDatum: nil,
            gehalt: nil,
            vertragsdetails: nil
        )),
        isEditing: false,
        onSave: { _ in },
        onCancel: {}
    )
    .environmentObject(AuthManager())
}
