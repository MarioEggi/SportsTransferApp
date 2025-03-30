import SwiftUI
import FirebaseFirestore
import PhotosUI

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var typ = "Spieler"
    @State private var vorname: String = ""
    @State private var name: String = ""
    @State private var geschlecht = "männlich"
    @State private var vereinID: String? = nil
    @State private var vertragBis: Date = Date()
    @State private var vertragsOptionen: String = ""
    @State private var gehalt: String = ""
    @State private var groesse: String = ""
    @State private var nationalmannschaft: String = ""
    @State private var positionFeld: [String] = []
    @State private var schuhmarke: String = ""
    @State private var starkerFuss: String = ""
    @State private var kontaktTelefon: String = ""
    @State private var kontaktEmail: String = ""
    @State private var adresse: String = ""
    @State private var geburtsdatum: Date = Date()
    @State private var clubOptions: [Club] = []
    @State private var sponsorOptions: [Sponsor] = []
    @State private var transfermarktID: String = ""
    @State private var errorMessage: String = ""
    @State private var showingPositionPicker = false
    @State private var showingNationalityPicker = false
    @State private var selectedNationalities: [String] = []
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isUploadingImage = false
    @State private var isLoadingTransfermarkt = false
    @State private var transfermarktError = ""
    @State private var liga: String?

    var body: some View {
        NavigationView {
            Form {
                clientTypeSection
                clientDataSection
                if typ == "Spieler" || typ == "Spielerin" {
                    positionSection
                }
                contactInfoSection
                transfermarktSection
            }
            .scrollContentBackground(.hidden) // Standard-Hintergrund der Form ausblenden
            .background(Color.black) // Schwarzer Hintergrund für die Form
            .navigationTitle("Neuer Klient")
            .foregroundColor(.white) // Weiße Schrift für den Titel
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(.white) // Weiße Schrift
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        Task { await saveClient() }
                    }
                    .disabled(!isValidClient())
                    .foregroundColor(.white) // Weiße Schrift
                }
            }
            .alert(isPresented: .constant(!errorMessage.isEmpty)) {
                Alert(
                    title: Text("Fehler").foregroundColor(.white),
                    message: Text(errorMessage).foregroundColor(.white),
                    dismissButton: .default(Text("OK").foregroundColor(.white)) { errorMessage = "" }
                )
            }
            .onChange(of: selectedPhoto) { _ in
                Task { await loadSelectedImage() }
            }
            .task {
                await loadClubOptions()
                await loadSponsors()
            }
        }
    }

    private var clientTypeSection: some View {
        Section(header: Text("Kliententyp").foregroundColor(.white)) {
            Picker("Typ", selection: $typ) {
                Text("Spieler").tag("Spieler")
                Text("Spielerin").tag("Spielerin")
                Text("Trainer").tag("Trainer")
                Text("Sonstige").tag("Sonstige")
            }
            .pickerStyle(.segmented)
            .foregroundColor(.white) // Weiße Schrift
            .accentColor(.white) // Weiße Akzente

            Picker("Geschlecht", selection: $geschlecht) {
                Text("Männlich").tag("männlich")
                Text("Weiblich").tag("weiblich")
            }
            .pickerStyle(.segmented)
            .foregroundColor(.white) // Weiße Schrift
            .accentColor(.white) // Weiße Akzente
        }
    }

    private var clientDataSection: some View {
        Section(header: Text("Klientendaten").foregroundColor(.white)) {
            TextField("Vorname", text: $vorname)
                .foregroundColor(.white) // Weiße Schrift
            TextField("Name", text: $name)
                .foregroundColor(.white) // Weiße Schrift
            DatePicker("Geburtsdatum", selection: $geburtsdatum, displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundColor(.white) // Weiße Schrift
                .accentColor(.white) // Weiße Akzente
            Picker("Verein", selection: $vereinID) {
                Text("Kein Verein").tag(String?.none)
                ForEach(clubOptions.filter { $0.abteilungForGender(geschlecht) != nil }) { club in
                    Text(club.name).tag(club.id as String?)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white) // Weiße Schrift
            .accentColor(.white) // Weiße Akzente
            .onChange(of: vereinID) { _ in updateLeagueAndAbteilung() }
            Text("Liga: \(liga ?? "Keine")")
                .foregroundColor(.gray)
            DatePicker("Vertragslaufzeit", selection: $vertragBis, displayedComponents: .date)
                .foregroundColor(.white) // Weiße Schrift
                .accentColor(.white) // Weiße Akzente
            TextField("Vertragsoptionen", text: $vertragsOptionen)
                .foregroundColor(.white) // Weiße Schrift
            TextField("Gehalt (€)", text: $gehalt)
                .keyboardType(.decimalPad)
                .foregroundColor(.white) // Weiße Schrift
            TextField("Größe (cm)", text: $groesse)
                .keyboardType(.numberPad)
                .foregroundColor(.white) // Weiße Schrift
            profileImagePicker
            nationalityPicker
            TextField("Nationalmannschaft", text: $nationalmannschaft)
                .foregroundColor(.white) // Weiße Schrift
        }
    }

    private var positionSection: some View {
        Section(header: Text("Positionen").foregroundColor(.white)) {
            Button(action: { showingPositionPicker = true }) {
                Text(positionFeld.isEmpty ? "Positionen auswählen" : positionFeld.joined(separator: ", "))
                    .foregroundColor(positionFeld.isEmpty ? .gray : .white) // Weiße Schrift
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .sheet(isPresented: $showingPositionPicker) {
                NavigationView {
                    MultiPicker(
                        title: "Positionen auswählen",
                        selection: $positionFeld,
                        options: Constants.positionOptions,
                        isNationalityPicker: false
                    )
                    .foregroundColor(.white) // Weiße Schrift
                    .navigationTitle("Positionen")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fertig") { showingPositionPicker = false }
                                .foregroundColor(.white) // Weiße Schrift
                        }
                    }
                }
                .background(Color.black) // Schwarzer Hintergrund für die Sheet-View
            }
            Picker("Schuhmarke", selection: $schuhmarke) {
                Text("Keine Marke").tag("")
                ForEach(sponsorOptions.filter { $0.category == "Sportartikelhersteller" }) { sponsor in
                    Text(sponsor.name).tag(sponsor.name)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white) // Weiße Schrift
            .accentColor(.white) // Weiße Akzente
            Picker("Starker Fuß", selection: $starkerFuss) {
                Text("Nicht angegeben").tag("")
                ForEach(Constants.strongFootOptions, id: \.self) { foot in
                    Text(foot).tag(foot)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white) // Weiße Schrift
            .accentColor(.white) // Weiße Akzente
        }
    }

    private var contactInfoSection: some View {
        Section(header: Text("Kontaktinformationen").foregroundColor(.white)) {
            TextField("Telefon", text: $kontaktTelefon)
                .foregroundColor(.white) // Weiße Schrift
            TextField("E-Mail", text: $kontaktEmail)
                .foregroundColor(.white) // Weiße Schrift
            TextField("Adresse", text: $adresse)
                .foregroundColor(.white) // Weiße Schrift
        }
    }

    private var transfermarktSection: some View {
        Section {
            TextField(geschlecht == "männlich" ? "Transfermarkt-ID" : "Soccerdonna-ID", text: $transfermarktID)
                .keyboardType(.numberPad)
                .foregroundColor(.white) // Weiße Schrift
                .customPlaceholder(when: transfermarktID.isEmpty) {
                    Text(geschlecht == "männlich" ? "z. B. 690425" : "z. B. 31388")
                        .foregroundColor(.gray)
                }
                .onChange(of: transfermarktID) { newID in
                    if !newID.isEmpty {
                        Task {
                            await MainActor.run { isLoadingTransfermarkt = true }
                            do {
                                let playerData: PlayerData
                                if geschlecht == "männlich" {
                                    playerData = try await TransfermarktService.shared.fetchPlayerData(forPlayerID: newID)
                                } else {
                                    playerData = try await SoccerdonnaService.shared.fetchPlayerData(forPlayerID: newID)
                                }
                                await MainActor.run {
                                    isLoadingTransfermarkt = false
                                    transfermarktError = ""
                                    if vorname.isEmpty, let fullName = playerData.name {
                                        let parts = fullName.split(separator: " ")
                                        if parts.count >= 2 {
                                            vorname = String(parts[0])
                                            name = String(parts.dropFirst().joined(separator: " "))
                                        } else {
                                            name = fullName
                                        }
                                    }
                                    if positionFeld.isEmpty, let position = playerData.position {
                                        positionFeld = [position]
                                    }
                                    if selectedNationalities.isEmpty, let nationalities = playerData.nationalitaet {
                                        selectedNationalities = nationalities
                                    }
                                    if geburtsdatum == Date(), let birthdate = playerData.geburtsdatum {
                                        geburtsdatum = birthdate
                                    }
                                    if vereinID == nil, let clubID = playerData.vereinID,
                                       let club = clubOptions.first(where: { $0.name == clubID }) {
                                        vereinID = club.id
                                        updateLeagueAndAbteilung()
                                    }
                                    if vertragBis == Date(), let contractEnd = playerData.contractEnd {
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
                    .tint(.white) // Weißer Ladeindikator
            }
            if !transfermarktError.isEmpty {
                Text(transfermarktError)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        } header: {
            Text(geschlecht == "männlich" ? "Transfermarkt" : "Soccerdonna")
                .foregroundColor(.white) // Weiße Schrift
        }
    }
    
    private var profileImagePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profilbild")
                .font(.subheadline)
                .foregroundColor(.white) // Weiße Schrift
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("Bild auswählen", systemImage: "photo")
                    .foregroundColor(.white) // Weiße Schrift und Symbol
            }
            if isUploadingImage {
                ProgressView("Bild wird hochgeladen...")
                    .tint(.white) // Weißer Ladeindikator
            } else if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var nationalityPicker: some View {
        Button(action: { showingNationalityPicker = true }) {
            Text(selectedNationalities.isEmpty ? "Nationalitäten auswählen" : selectedNationalities.joined(separator: ", "))
                .foregroundColor(selectedNationalities.isEmpty ? .gray : .white) // Weiße Schrift
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
                .foregroundColor(.white) // Weiße Schrift
                .navigationTitle("Nationalitäten")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fertig") { showingNationalityPicker = false }
                            .foregroundColor(.white) // Weiße Schrift
                    }
                }
            }
            .background(Color.black) // Schwarzer Hintergrund für die Sheet-View
        }
    }

    private func loadClubOptions() async {
        do {
            let (clubs, _) = try await FirestoreManager.shared.getClubs(lastDocument: nil as DocumentSnapshot?, limit: 1000)
            await MainActor.run {
                self.clubOptions = clubs
                updateLeagueAndAbteilung()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden der Vereine: \(error.localizedDescription)"
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
                errorMessage = "Fehler beim Laden der Sponsoren: \(error.localizedDescription)"
                self.sponsorOptions = []
            }
        }
    }

    private func updateLeagueAndAbteilung() {
        if let vereinID = vereinID,
           let selectedClub = clubOptions.first(where: { $0.id == vereinID }) {
            let abteilung = selectedClub.abteilungForGender(geschlecht)
            if geschlecht == "männlich" {
                liga = selectedClub.mensDepartment?.league
            } else if geschlecht == "weiblich" {
                liga = selectedClub.womensDepartment?.league
            }
        } else {
            liga = nil
        }
    }

    private func loadSelectedImage() async {
        guard let photoItem = selectedPhoto else { return }
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
            }
        }
    }

    private func saveClient() async {
        do {
            var newClient = Client(
                id: nil,
                typ: typ,
                name: name,
                vorname: vorname,
                geschlecht: geschlecht,
                abteilung: nil, // Wird später basierend auf Verein und Geschlecht gesetzt, falls nötig
                vereinID: vereinID,
                nationalitaet: selectedNationalities.isEmpty ? nil : selectedNationalities,
                geburtsdatum: geburtsdatum,
                // `alter` wird entfernt, da es eine berechnete Eigenschaft ist
                kontaktTelefon: kontaktTelefon.isEmpty ? nil : kontaktTelefon,
                kontaktEmail: kontaktEmail.isEmpty ? nil : kontaktEmail,
                adresse: adresse.isEmpty ? nil : adresse,
                liga: liga,
                vertragBis: vertragBis,
                vertragsOptionen: vertragsOptionen.isEmpty ? nil : vertragsOptionen,
                gehalt: Double(gehalt),
                konditionen: nil, // Fehlt in deiner View, ggf. später hinzufügen
                art: nil, // Fehlt in deiner View, ggf. später hinzufügen
                spielerCV: nil, // Fehlt in deiner View, ggf. später hinzufügen
                video: nil, // Fehlt in deiner View, ggf. später hinzufügen
                schuhgroesse: nil, // Fehlt in deiner View, ggf. später hinzufügen
                schuhmarke: schuhmarke.isEmpty ? nil : schuhmarke,
                starkerFuss: starkerFuss.isEmpty ? nil : starkerFuss,
                groesse: Int(groesse),
                gewicht: nil, // Fehlt in deiner View, ggf. später hinzufügen
                positionFeld: positionFeld.isEmpty ? nil : positionFeld,
                sprachen: nil, // Fehlt in deiner View, ggf. später hinzufügen
                lizenz: nil, // Fehlt in deiner View, ggf. später hinzufügen
                nationalmannschaft: nationalmannschaft.isEmpty ? nil : nationalmannschaft,
                profilbildURL: nil,
                transfermarktID: transfermarktID.isEmpty ? nil : transfermarktID,
                userID: authManager.userID, // Verwende die aktuelle userID aus authManager
                createdBy: authManager.currentUser?.email
            )
            let clientID = try await FirestoreManager.shared.createClient(client: newClient)
            newClient.id = clientID
            if let image = profileImage {
                await MainActor.run { isUploadingImage = true }
                let url = try await FirestoreManager.shared.uploadImage(
                    documentID: clientID,
                    image: image,
                    collection: "profile_images"
                )
                newClient.profilbildURL = url
                try await FirestoreManager.shared.updateClient(client: newClient)
                await MainActor.run { isUploadingImage = false }
            }
            dismiss()
        } catch {
            await MainActor.run {
                errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                isUploadingImage = false
            }
        }
    }

    private func isValidClient() -> Bool {
        if vorname.isEmpty || name.isEmpty {
            errorMessage = "Vorname und Name sind Pflichtfelder."
            return false
        }
        if !kontaktEmail.isEmpty && !isValidEmail(kontaktEmail) {
            errorMessage = "Ungültiges E-Mail-Format."
            return false
        }
        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
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
    AddClientView()
        .environmentObject(AuthManager())
}
