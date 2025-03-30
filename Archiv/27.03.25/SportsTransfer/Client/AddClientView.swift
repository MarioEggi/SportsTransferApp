import SwiftUI
import FirebaseFirestore
import PhotosUI
import FirebaseAuth

struct AddClientView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var client: Client
    var isEditing: Bool
    var onSave: (Client) -> Void
    var onCancel: () -> Void

    @State private var clubOptions: [Club] = []
    @State private var sponsorOptions: [Sponsor] = []
    @State private var showingPositionPicker = false
    @State private var showingNationalityPicker = false
    @State private var selectedPositions: [String] = []
    @State private var selectedNationalities: [String] = []
    @State private var nationalitySearchText: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoadingTransfermarkt = false
    @State private var transfermarktError = ""
    @State private var vertragBis: Date = Date()
    @State private var vertragsOptionen: String = ""
    @State private var gehalt: String = ""
    @State private var groesse: String = ""
    @State private var nationalmannschaft: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Typ", selection: $client.typ) {
                        ForEach(Constants.clientTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Vorname", text: $client.vorname)
                    TextField("Nachname", text: $client.name)
                    DatePicker("Geburtsdatum", selection: Binding(
                        get: { client.geburtsdatum ?? Date() },
                        set: { client.geburtsdatum = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)

                    Picker("Geschlecht", selection: $client.geschlecht) {
                        ForEach(Constants.genderOptions, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: client.geschlecht) { _ in
                        client.liga = nil
                        client.vereinID = nil
                        client.abteilung = client.geschlecht == "männlich" ? "Männer" : "Frauen"
                        Task { await loadOptions() }
                    }

                    Picker("Verein", selection: $client.vereinID) {
                        Text("Kein Verein").tag(String?.none)
                        ForEach(clubOptions.filter { $0.abteilungForGender(client.geschlecht) != nil }) { club in
                            Text(club.name).tag(club.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: client.vereinID) { newValue in
                        print("Verein ausgewählt: \(newValue ?? "Kein Verein")")
                        updateAbteilungAndLeague()
                    }

                    Text("Abteilung: \(client.abteilung ?? "Keine")")
                        .foregroundColor(.gray)

                    Text("Liga: \(client.liga ?? "Keine")")
                        .foregroundColor(.gray)

                    DatePicker("Vertragslaufzeit", selection: $vertragBis, displayedComponents: .date)
                    TextField("Vertragsoptionen", text: $vertragsOptionen)
                    TextField("Gehalt (€)", text: $gehalt)
                        .keyboardType(.decimalPad)
                    TextField("Größe (cm)", text: $groesse)
                        .keyboardType(.numberPad)

                    profileImagePicker

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
                                        client.nationalitaet = selectedNationalities.isEmpty ? nil : selectedNationalities
                                        showingNationalityPicker = false
                                    }
                                }
                            }
                        }
                    }

                    TextField("Nationalmannschaft", text: $nationalmannschaft)

                    if client.typ == "Trainer" || client.typ == "Co-Trainer" {
                        TextField("Lizenz", text: Binding(
                            get: { client.lizenz ?? "" },
                            set: { client.lizenz = $0.isEmpty ? nil : $0 }
                        ))
                    }
                } header: {
                    Text("Klientendaten")
                }

                if client.typ == "Spieler" || client.typ == "Spielerin" {
                    Section {
                        Button(action: { showingPositionPicker = true }) {
                            Text(selectedPositions.isEmpty ? "Positionen auswählen" : selectedPositions.joined(separator: ", "))
                                .foregroundColor(selectedPositions.isEmpty ? .gray : .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .sheet(isPresented: $showingPositionPicker) {
                            NavigationView {
                                MultiPicker(
                                    title: "Positionen auswählen",
                                    selection: $selectedPositions,
                                    options: Constants.positionOptions,
                                    isNationalityPicker: false
                                )
                                .navigationTitle("Positionen")
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button("Fertig") {
                                            client.positionFeld = selectedPositions.isEmpty ? nil : selectedPositions
                                            showingPositionPicker = false
                                        }
                                    }
                                }
                            }
                        }

                        TextField("Schuhgröße", value: Binding(
                            get: { client.schuhgroesse ?? 0 },
                            set: { client.schuhgroesse = $0 == 0 ? nil : $0 }
                        ), format: .number)

                        Picker("Schuhmarke", selection: $client.schuhmarke) {
                            Text("Keine Marke").tag(String?.none)
                            ForEach(sponsorOptions.filter { $0.category == "Sportartikelhersteller" }) { sponsor in
                                Text(sponsor.name).tag(String?.some(sponsor.name))
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Starker Fuß", selection: $client.starkerFuss) {
                            Text("Nicht angegeben").tag(String?.none)
                            ForEach(Constants.strongFootOptions, id: \.self) { foot in
                                Text(foot).tag(String?.some(foot))
                            }
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text("Positionen")
                    }
                }

                Section {
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
                } header: {
                    Text("Kontaktinformationen")
                }

                Section(header: Text(client.geschlecht == "männlich" ? "Transfermarkt" : "Soccerdonna")) {
                    TextField(client.geschlecht == "männlich" ? "Transfermarkt-ID" : "Soccerdonna-ID", text: Binding(
                        get: { client.transfermarktID ?? "" },
                        set: { client.transfermarktID = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.numberPad)
                    .customPlaceholder(when: client.transfermarktID?.isEmpty ?? true) {
                        Text(client.geschlecht == "männlich" ? "z. B. 690425" : "z. B. 31388")
                            .foregroundColor(.gray)
                    }
                    .onChange(of: client.transfermarktID) { newID in
                        if let id = newID, !id.isEmpty {
                            Task {
                                await MainActor.run { isLoadingTransfermarkt = true }
                                do {
                                    let playerData: PlayerData
                                    if client.geschlecht == "männlich" {
                                        playerData = try await TransfermarktService.shared.fetchPlayerData(forPlayerID: id)
                                    } else {
                                        playerData = try await SoccerdonnaService.shared.fetchPlayerData(forPlayerID: id)
                                    }
                                    await MainActor.run {
                                        isLoadingTransfermarkt = false
                                        transfermarktError = ""
                                        if client.vorname.isEmpty, let fullName = playerData.name {
                                            let parts = fullName.split(separator: " ")
                                            if parts.count >= 2 {
                                                client.vorname = String(parts[0])
                                                client.name = String(parts.dropFirst().joined(separator: " "))
                                            } else {
                                                client.name = fullName
                                            }
                                        }
                                        if selectedPositions.isEmpty, let position = playerData.position {
                                            selectedPositions = [position]
                                            client.positionFeld = selectedPositions
                                        }
                                        if selectedNationalities.isEmpty, let nationalities = playerData.nationalitaet {
                                            selectedNationalities = nationalities
                                            client.nationalitaet = selectedNationalities
                                        }
                                        if client.geburtsdatum == nil, let birthdate = playerData.geburtsdatum {
                                            client.geburtsdatum = birthdate
                                        }
                                        if client.vereinID == nil, let clubID = playerData.vereinID,
                                           let club = clubOptions.first(where: { $0.name == clubID }) {
                                            client.vereinID = club.id
                                            updateAbteilungAndLeague()
                                        }
                                        if client.vertragBis == nil, let contractEnd = playerData.contractEnd {
                                            client.vertragBis = contractEnd
                                            vertragBis = contractEnd
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        isLoadingTransfermarkt = false
                                        transfermarktError = "Fehler beim Abrufen der Daten: \(error.localizedDescription)"
                                    }
                                }
                            }
                        }
                    }
                    if isLoadingTransfermarkt {
                        ProgressView("Lade Daten...")
                    }
                    if !transfermarktError.isEmpty {
                        Text(transfermarktError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Klient bearbeiten" : "Neuer Klient")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        if isValidClient() {
                            updateClient()
                            onSave(client)
                        }
                    }
                }
            }
            .task {
                await loadOptions()
                await loadSponsors()
                loadClientPositions()
                if let nationalitaet = client.nationalitaet {
                    selectedNationalities = nationalitaet
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(title: Text("Fehler"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                    errorMessage = ""
                })
            }
        }
    }

    private func loadOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
                updateAbteilungAndLeague()
            }
        } catch {
            await MainActor.run {
                self.clubOptions = []
                self.errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
            }
        }
    }

    private func loadSponsors() async {
        do {
            let (sponsors, _) = try await FirestoreManager.shared.getSponsors(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.sponsorOptions = sponsors
            }
        } catch {
            await MainActor.run {
                self.sponsorOptions = []
                self.errorMessage = "Fehler beim Laden der Sponsoren: \(error.localizedDescription)"
            }
        }
    }

    private func updateAbteilungAndLeague() {
        if let vereinID = client.vereinID,
           let selectedClub = clubOptions.first(where: { $0.id == vereinID }) {
            client.abteilung = selectedClub.abteilungForGender(client.geschlecht)
            if client.geschlecht == "männlich" {
                client.liga = selectedClub.mensDepartment?.league
            } else if client.geschlecht == "weiblich" {
                client.liga = selectedClub.womensDepartment?.league
            }
        } else {
            client.abteilung = nil
            client.liga = nil
        }
    }

    private func updateClient() {
        client.vertragBis = vertragBis
        client.vertragsOptionen = vertragsOptionen.isEmpty ? nil : vertragsOptionen
        client.gehalt = Double(gehalt) ?? nil
        client.groesse = Int(groesse) ?? nil
        client.nationalmannschaft = nationalmannschaft.isEmpty ? nil : nationalmannschaft
        if let image = profileImage {
            client.profilbildURL = nil // Wird beim Speichern aktualisiert
        }
        // Generiere eine eindeutige userID für den Klienten
        if client.userID == nil {
            client.userID = UUID().uuidString
        }
        // Setze createdBy auf die userID des Mitarbeiters
        client.createdBy = authManager.currentUser?.uid
        print("AddClientView - Client vor Speichern: \(client)")
        updateAbteilungAndLeague()
    }

    private func loadClientPositions() {
        if let positions = client.positionFeld {
            selectedPositions = positions
        }
    }

    private func isValidClient() -> Bool {
        if client.name.isEmpty || client.vorname.isEmpty || client.geschlecht.isEmpty {
            errorMessage = "Name, Vorname und Geschlecht sind Pflichtfelder."
            return false
        }
        if client.kontaktEmail != nil && !isValidEmail(client.kontaktEmail!) {
            errorMessage = "Ungültiges E-Mail-Format."
            return false
        }
        if client.vereinID != nil && client.abteilung == nil {
            errorMessage = "Die ausgewählte Abteilung ist für das Geschlecht nicht verfügbar."
            return false
        }
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private var profileImagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profilbild")
                .font(.subheadline)
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Bild auswählen", systemImage: "photo")
                    .foregroundColor(.blue)
            }
            if isUploadingImage {
                ProgressView("Bild wird hochgeladen...")
            } else if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let urlString = client.profilbildURL, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure, .empty:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .foregroundColor(.gray)
            }
        }
    }
}

extension View {
    func customPlaceholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}

#Preview {
    AddClientView(
        client: Binding.constant(Client(
            id: nil,
            typ: "Spieler",
            name: "",
            vorname: "",
            geschlecht: "männlich",
            abteilung: nil,
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
    .environmentObject(AuthManager())
}
