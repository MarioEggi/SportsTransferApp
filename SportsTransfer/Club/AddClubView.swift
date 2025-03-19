import SwiftUI

struct AddClubView: View {
    @Binding var club: Club
    var onSave: (Club) -> Void
    var onCancel: () -> Void

    @State private var name: String
    @State private var league: String = ""
    @State private var abteilung: String = "" // Kein Standardwert
    @State private var memberCount: String = ""
    @State private var founded: String = ""
    @State private var logoURL: String = ""
    @State private var kontaktTelefon: String = ""
    @State private var kontaktEmail: String = ""
    @State private var adresse: String = ""
    @State private var clients: String = ""
    @State private var land: String = ""

    init(club: Binding<Club>, onSave: @escaping (Club) -> Void, onCancel: @escaping () -> Void) {
        self._club = club
        self.onSave = onSave
        self.onCancel = onCancel
        self._name = State(initialValue: club.wrappedValue.name)
        self._league = State(initialValue: club.wrappedValue.league ?? "")
        self._abteilung = State(initialValue: club.wrappedValue.abteilung ?? "")
        self._memberCount = State(initialValue: club.wrappedValue.memberCount.map(String.init) ?? "")
        self._founded = State(initialValue: club.wrappedValue.founded ?? "")
        self._logoURL = State(initialValue: club.wrappedValue.logoURL ?? "")
        self._kontaktTelefon = State(initialValue: club.wrappedValue.kontaktTelefon ?? "")
        self._kontaktEmail = State(initialValue: club.wrappedValue.kontaktEmail ?? "")
        self._adresse = State(initialValue: club.wrappedValue.adresse ?? "")
        self._clients = State(initialValue: club.wrappedValue.clients?.joined(separator: ", ") ?? "")
        self._land = State(initialValue: club.wrappedValue.land ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vereinsdaten")) {
                    TextField("Name", text: $name)
                    TextField("Liga", text: $league)
                    Picker("Abteilung", selection: $abteilung) {
                        Text("Bitte auswählen").tag("")
                        Text("Männer").tag("Männer")
                        Text("Frauen").tag("Frauen")
                    }
                    .pickerStyle(.menu)
                    TextField("Mitgliederzahl", text: $memberCount)
                        .keyboardType(.numberPad)
                    TextField("Gegründet", text: $founded)
                    TextField("Logo-URL", text: $logoURL)
                    TextField("Telefon", text: $kontaktTelefon)
                    TextField("E-Mail", text: $kontaktEmail)
                    TextField("Adresse", text: $adresse)
                    TextField("Klienten (durch Komma getrennt)", text: $clients)
                    TextField("Land", text: $land)
                }
            }
            .navigationTitle("Verein anlegen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedClub = Club(
                            name: name,
                            league: league.isEmpty ? nil : league,
                            abteilung: abteilung.isEmpty ? nil : abteilung,
                            kontaktTelefon: kontaktTelefon.isEmpty ? nil : kontaktTelefon,
                            kontaktEmail: kontaktEmail.isEmpty ? nil : kontaktEmail,
                            adresse: adresse.isEmpty ? nil : adresse,
                            clients: clients.isEmpty ? nil : clients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                            land: land.isEmpty ? nil : land,
                            memberCount: Int(memberCount) ?? nil,
                            founded: founded.isEmpty ? nil : founded,
                            logoURL: logoURL.isEmpty ? nil : logoURL
                        )
                        onSave(updatedClub)
                    }
                    .disabled(abteilung.isEmpty || name.isEmpty) // Deaktiviere Button, wenn keine Abteilung oder kein Name ausgewählt
                }
            }
        }
    }
}

#Preview {
    let club = Club(name: "Bayern München")
    return AddClubView(club: .constant(club), onSave: { _ in }, onCancel: {})
}
