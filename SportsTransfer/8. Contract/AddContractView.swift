import SwiftUI
import FirebaseFirestore

struct AddContractView: View {
    @Binding var contract: Contract
    var isEditing: Bool
    var onSave: (Contract) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

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

    // Farben für das helle Design
    private let backgroundColor = Color(hex: "#F5F5F5")
    private let cardBackgroundColor = Color(hex: "#E0E0E0")
    private let accentColor = Color(hex: "#00C4B4")
    private let textColor = Color(hex: "#333333")
    private let secondaryTextColor = Color(hex: "#666666")

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                List {
                    contractSection
                }
                .listStyle(PlainListStyle())
                .listRowInsets(EdgeInsets(top: 3, leading: 13, bottom: 3, trailing: 13))
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
                .tint(accentColor)
                .foregroundColor(textColor)
                .navigationTitle(isEditing ? "Vertrag bearbeiten" : "Vertrag anlegen")
                .toolbar { toolbarItems() }
                .sheet(isPresented: $showingAddClubSheet) { addClubSheet }
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
    }

    // Sektion für Vertragsdaten oder Platzhalter
    private var contractSection: some View {
        Section(header: Text(authManager.userRole == .mitarbeiter ? "Vertragsdaten" : "").foregroundColor(textColor)) {
            if authManager.userRole == .mitarbeiter {
                contractForm
            } else {
                Text("Nur Mitarbeiter können Verträge bearbeiten.")
                    .foregroundColor(secondaryTextColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
    }

    // Formular für Vertragsdaten
    private var contractForm: some View {
        VStack(spacing: 10) {
            clientPicker
            vereinPickerSection
            startDatePicker
            endDatePicker
            salaryField
            detailsField
        }
        .padding(.vertical, 8)
    }

    private var clientPicker: some View {
        Picker("Klient", selection: $selectedClient) {
            Text("Kein Klient ausgewählt").tag(Client?.none)
            ForEach(clients) { client in
                Text("\(client.vorname) \(client.name)")
                    .tag(client as Client?)
            }
        }
        .pickerStyle(.menu)
        .foregroundColor(textColor)
        .tint(accentColor)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private var vereinPickerSection: some View {
        VStack(spacing: 10) {
            Picker("Verein", selection: $selectedVerein) {
                Text("Kein Verein ausgewählt").tag(Club?.none)
                ForEach(clubs) { club in
                    Text(club.name).tag(club as Club?)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(textColor)
            .tint(accentColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            
            Button(action: { showingAddClubSheet = true }) {
                Label("Neuer Verein", systemImage: "plus.circle")
                    .foregroundColor(accentColor)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
    }

    private var startDatePicker: some View {
        DatePicker("Startdatum", selection: $startDatum, displayedComponents: .date)
            .foregroundColor(textColor)
            .tint(accentColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
    }

    private var endDatePicker: some View {
        DatePicker("Enddatum", selection: Binding(
            get: { endDatum ?? Date() },
            set: { endDatum = $0 }
        ), displayedComponents: .date)
            .foregroundColor(textColor)
            .tint(accentColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
    }

    private var salaryField: some View {
        TextField("Gehalt (€)", value: $gehalt, format: .number)
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
    }

    private var detailsField: some View {
        TextField("Vertragsdetails", text: Binding(
            get: { vertragsdetails ?? "" },
            set: { vertragsdetails = $0.isEmpty ? nil : $0 }
        ))
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
    }

    private func toolbarItems() -> some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { onCancel() }
                    .foregroundColor(accentColor)
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
                            dismiss()
                        }
                    }
                    .disabled(selectedClient == nil || selectedVerein == nil)
                    .foregroundColor(accentColor)
                }
            }
        }
    }

    private var addClubSheet: some View {
        AddClubView(
            club: $newClub, // Korrektes Label: 'club' statt 'contract'
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

    private func loadClients() async {
        do {
            let (loadedClients, _) = try await FirestoreManager.shared.getClients(lastDocument: nil, limit: 1000)
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
            let (loadedClubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil, limit: 1000)
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
