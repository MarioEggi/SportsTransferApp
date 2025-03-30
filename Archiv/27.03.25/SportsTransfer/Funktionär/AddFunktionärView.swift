import SwiftUI
import FirebaseFirestore

struct AddFunktionärView: View {
    @Binding var funktionär: Funktionär
    let onSave: (Funktionär) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var vorname: String
    @State private var vereinID: String?
    @State private var abteilung: String?
    @State private var positionImVerein: String?
    @State private var kontaktTelefon: String?
    @State private var kontaktEmail: String?
    @State private var adresse: String?
    @State private var geburtsdatum: Date?
    @State private var mannschaft: String?
    @State private var clubOptions: [Club] = []
    @State private var showingNationalityPicker = false
    @State private var selectedNationalities: [String] = []

    init(funktionär: Binding<Funktionär>, onSave: @escaping (Funktionär) -> Void, onCancel: @escaping () -> Void) {
        self._funktionär = funktionär
        self.onSave = onSave
        self.onCancel = onCancel
        self._name = State(initialValue: funktionär.wrappedValue.name)
        self._vorname = State(initialValue: funktionär.wrappedValue.vorname)
        self._vereinID = State(initialValue: funktionär.wrappedValue.vereinID)
        self._abteilung = State(initialValue: funktionär.wrappedValue.abteilung)
        self._positionImVerein = State(initialValue: funktionär.wrappedValue.positionImVerein)
        self._kontaktTelefon = State(initialValue: funktionär.wrappedValue.kontaktTelefon)
        self._kontaktEmail = State(initialValue: funktionär.wrappedValue.kontaktEmail)
        self._adresse = State(initialValue: funktionär.wrappedValue.adresse)
        self._geburtsdatum = State(initialValue: funktionär.wrappedValue.geburtsdatum)
        self._mannschaft = State(initialValue: funktionär.wrappedValue.mannschaft)
        self._selectedNationalities = State(initialValue: funktionär.wrappedValue.nationalitaet ?? [])
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Vorname", text: $vorname)
                    Picker("Verein", selection: $vereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubOptions) { club in
                            Text(club.name).tag(club.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: vereinID) { _ in abteilung = nil }

                    if let selectedVereinID = vereinID,
                       let selectedClub = clubOptions.first(where: { $0.id == selectedVereinID }) {
                        Picker("Abteilung", selection: $abteilung) {
                            Text("Keine Abteilung").tag(String?.none)
                            if selectedClub.mensDepartment != nil {
                                Text("Männer").tag("Männer" as String?)
                            }
                            if selectedClub.womensDepartment != nil {
                                Text("Frauen").tag("Frauen" as String?)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker("Position im Verein", selection: $positionImVerein) {
                        Text("Keine Position").tag(String?.none)
                        ForEach(Constants.functionaryPositionOptions, id: \.self) { position in
                            Text(position).tag(String?.some(position))
                        }
                    }
                    .pickerStyle(.menu)

                    Button(action: { showingNationalityPicker = true }) {
                        Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                            .foregroundColor(selectedNationalities.isEmpty ? .gray : .black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sheet(isPresented: $showingNationalityPicker) {
                        NavigationView {
                            MultiPicker(
                                title: "Nationalitäten auswählen",
                                selection: $selectedNationalities,
                                options: Constants.nationalities,
                                isNationalityPicker: true
                            )
                            .navigationTitle("Nationalitäten")
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Fertig") {
                                        funktionär.nationalitaet = selectedNationalities.isEmpty ? nil : selectedNationalities
                                        showingNationalityPicker = false
                                    }
                                }
                            }
                        }
                    }

                    TextField("Telefon", text: Binding(
                        get: { kontaktTelefon ?? "" },
                        set: { kontaktTelefon = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("E-Mail", text: Binding(
                        get: { kontaktEmail ?? "" },
                        set: { kontaktEmail = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Adresse", text: Binding(
                        get: { adresse ?? "" },
                        set: { adresse = $0.isEmpty ? nil : $0 }
                    ))
                    DatePicker("Geburtsdatum", selection: Binding(
                        get: { geburtsdatum ?? Date() },
                        set: { geburtsdatum = $0 }
                    ), displayedComponents: .date)
                    TextField("Mannschaft", text: Binding(
                        get: { mannschaft ?? "" },
                        set: { mannschaft = $0.isEmpty ? nil : $0 }
                    ))
                } header: {
                    Text("Funktionär-Daten")
                }
            }
            .navigationTitle("Funktionär hinzufügen/bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let updatedFunktionär = Funktionär(
                            id: funktionär.id,
                            name: name,
                            vorname: vorname,
                            abteilung: abteilung,
                            vereinID: vereinID,
                            kontaktTelefon: kontaktTelefon,
                            kontaktEmail: kontaktEmail,
                            adresse: adresse,
                            clients: funktionär.clients,
                            profilbildURL: funktionär.profilbildURL,
                            geburtsdatum: geburtsdatum,
                            positionImVerein: positionImVerein,
                            mannschaft: mannschaft,
                            nationalitaet: selectedNationalities.isEmpty ? nil : selectedNationalities
                        )
                        onSave(updatedFunktionär)
                    }
                    .disabled(name.isEmpty || vorname.isEmpty || (vereinID != nil && abteilung == nil))
                }
            }
            .task {
                await loadClubOptions()
            }
        }
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
            }
        } catch {
            print("Fehler beim Laden der Vereine: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddFunktionärView(
        funktionär: .constant(Funktionär(
            name: "Mustermann",
            vorname: "Max",
            abteilung: "Männer",
            positionImVerein: "Trainer"
        )),
        onSave: { _ in },
        onCancel: {}
    )
}
