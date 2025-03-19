import SwiftUI
import FirebaseFirestore

struct AddClientView: View {
    @Binding var client: Client
    var isEditing: Bool
    var onSave: (Client) -> Void
    var onCancel: () -> Void

    @State private var clubOptions: [String] = []
    @State private var showingPositionPicker = false
    @State private var selectedPositions: [String: Bool] = [
        "Tor": false,
        "Innenverteidigung rechts": false,
        "Innenverteidigung links": false,
        "Aussenverteidiger rechts": false,
        "Aussenverteidiger links": false,
        "Defensives Mittelfeld 6": false,
        "Zentrales Mittelfeld 8": false,
        "Offensives Mittelfeld 10": false,
        "Mittelfeld rechts": false,
        "Mittelfeld links": false,
        "Aussenstürmer rechts": false,
        "Aussenstürmer links": false,
        "Mittelstürmer": false
    ]
    @State private var nationalities: [String] = []

    private var leagues: [String] {
        if client.geschlecht == "männlich" {
            return ["1. Bundesliga", "2. Bundesliga", "Regionalliga", "Serie A", "Serie B", "Premier League", "EFL Championship", "Super League CH", "Challenge League CH", "1. Bundesliga AUT", "La Liga", "MLS"]
        } else {
            return ["1. Bundesliga", "2. Bundesliga", "Regionalliga", "WSL CH", "FA WSL 1", "FA WSL 2", "NWSL", "ÖFB Frauen Bundesliga", "Serie A", "Serie B", "Primera Division SPA"]
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Klientendaten")) {
                    Picker("Typ", selection: $client.typ) {
                        Text("Spieler").tag("Spieler")
                        Text("Spielerin").tag("Spielerin")
                        Text("Trainer").tag("Trainer")
                        Text("Co-Trainer").tag("Co-Trainer")
                    }
                    .pickerStyle(.menu)

                    TextField("Vorname", text: $client.vorname)
                    TextField("Nachname", text: $client.name)
                    DatePicker("Geburtsdatum", selection: Binding(
                        get: { client.geburtsdatum ?? Date() },
                        set: { client.geburtsdatum = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.wheel)

                    Picker("Geschlecht", selection: $client.geschlecht) {
                        Text("männlich").tag("männlich")
                        Text("weiblich").tag("weiblich")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: client.geschlecht) { _ in
                        client.liga = nil // Zurücksetzen der Liga bei Geschlechtsänderung
                        Task { await loadOptions() } // Neu laden der Vereinsliste bei Geschlechtsänderung
                    }

                    Picker("Liga", selection: $client.liga) {
                        Text("Keine Liga").tag(String?.none)
                        ForEach(leagues, id: \.self) { league in
                            Text(league).tag(String?.some(league))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Verein", selection: $client.vereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubOptions, id: \.self) { club in
                            Text(club).tag(String?.some(club))
                        }
                    }
                    .pickerStyle(.menu)

                    // Eingabefeld für mehrere Nationalitäten
                    TextField("Nationalitäten (durch Komma getrennt)", text: Binding(
                        get: { nationalities.joined(separator: ", ") },
                        set: { nationalities = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                    ))
                    .onChange(of: nationalities) { newValue in
                        client.nationalitaet = newValue.isEmpty ? nil : newValue
                    }

                    if client.typ == "Trainer" || client.typ == "Co-Trainer" {
                        TextField("Lizenz", text: Binding(
                            get: { client.lizenz ?? "" },
                            set: { client.lizenz = $0.isEmpty ? nil : $0 }
                        ))
                    }

                    if client.typ == "Spieler" || client.typ == "Spielerin" {
                        Section(header: Text("Positionen")) {
                            Button(action: {
                                showingPositionPicker = true
                            }) {
                                Text(client.positionFeld?.isEmpty ?? true ? "Positionen auswählen" : client.positionFeld!.joined(separator: ", "))
                                    .foregroundColor(client.positionFeld?.isEmpty ?? true ? .gray : .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .sheet(isPresented: $showingPositionPicker) {
                            PositionPickerView(selectedPositions: $selectedPositions, onDone: {
                                updateClientPositions()
                                showingPositionPicker = false
                            })
                        }

                        TextField("Schuhgröße", value: Binding(
                            get: { client.schuhgroesse ?? 0 },
                            set: { client.schuhgroesse = $0 == 0 ? nil : $0 }
                        ), format: .number)
                        TextField("Schuhmarke", text: Binding(
                            get: { client.schuhmarke ?? "" },
                            set: { client.schuhmarke = $0.isEmpty ? nil : $0 }
                        ))
                        Picker("Starker Fuß", selection: $client.starkerFuss) {
                            Text("Nicht angegeben").tag(String?.none)
                            Text("rechts").tag(String?.some("rechts"))
                            Text("links").tag(String?.some("links"))
                            Text("beide").tag(String?.some("beide"))
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section(header: Text("Kontaktinformationen")) {
                    TextField("Telefon", text: Binding(
                        get: { client.kontaktTelefon ?? "" },
                        set: { client.kontaktTelefon = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("E-Mail", text: Binding(
                        get: { client.kontaktEmail ?? "" },
                        set: { client.kontaktEmail = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Adresse", text: Binding(
                        get: { client.adresse ?? "" },
                        set: { client.adresse = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle(isEditing ? "Klient bearbeiten" : "Neuer Klient")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") { onSave(client) }
                }
            }
            .task {
                await loadOptions()
                loadClientPositions()
                // Initialisiere nationalities mit den vorhandenen Werten
                if let nationalitaet = client.nationalitaet {
                    nationalities = nationalitaet
                }
            }
        }
    }

    private func loadOptions() async {
        do {
            let clubs = try await FirestoreManager.shared.getClubs()
            await MainActor.run {
                self.clubOptions = clubs.filter { club in
                    if client.geschlecht == "männlich" {
                        return club.abteilung == "Männer" || club.abteilung == "gemischt"
                    } else if client.geschlecht == "weiblich" {
                        return club.abteilung == "Frauen" || club.abteilung == "gemischt"
                    }
                    return false
                }.map { $0.name }
                if let currentVereinID = client.vereinID, !clubOptions.contains(currentVereinID) {
                    self.clubOptions.insert(currentVereinID, at: 0)
                }
            }
        } catch {
            await MainActor.run {
                self.clubOptions = []
            }
        }
    }

    private func loadClientPositions() {
        if let positions = client.positionFeld {
            for position in positions {
                selectedPositions[position] = true
            }
        }
    }

    private func updateClientPositions() {
        client.positionFeld = selectedPositions.filter { $0.value }.map { $0.key }
    }
}

struct PositionPickerView: View {
    @Binding var selectedPositions: [String: Bool]
    var onDone: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Positionen auswählen")) {
                    ForEach(Array(selectedPositions.keys).sorted(), id: \.self) { position in
                        Toggle(position, isOn: Binding(
                            get: { selectedPositions[position] ?? false },
                            set: { selectedPositions[position] = $0 }
                        ))
                    }
                }
            }
            .navigationTitle("Positionen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onDone() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { onDone() }
                }
            }
        }
    }
}

#Preview {
    AddClientView(
        client: .constant(Client(
            id: nil,
            typ: "Spieler",
            name: "",
            vorname: "",
            geschlecht: "männlich",
            vereinID: nil,
            nationalitaet: [],
            geburtsdatum: nil,
            liga: nil,
            profilbildURL: nil
        )),
        isEditing: false,
        onSave: { _ in },
        onCancel: {}
    )
}
